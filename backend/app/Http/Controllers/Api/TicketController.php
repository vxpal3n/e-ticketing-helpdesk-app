<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ticket;
use App\Models\TicketHistory;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TicketController extends Controller
{
    // Fungsi bantuan untuk membuat Notifikasi
    private function sendNotification($userId, $ticketId, $title, $message)
    {
        Notification::create([
            'user_id' => $userId,
            'ticket_id' => $ticketId,
            'title' => $title,
            'message' => $message,
        ]);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        // --- UBAH BAGIAN INI: Tambahkan .user pada histories dan comments ---
        $query = Ticket::with(['user', 'helpdesk', 'histories.user', 'comments.user'])->orderBy('created_at', 'desc');

        if ($user->role === 'user') {
            $query->where('user_id', $user->id);
        } elseif ($user->role === 'helpdesk') {
            $query->where('helpdesk_id', $user->id);
        }

        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function show($id)
    {
        $ticket = Ticket::with(['user', 'helpdesk', 'histories.user', 'comments.user'])->findOrFail($id);
        return response()->json(['success' => true, 'data' => $ticket]);
    }

    // --- ALUR 1: BUAT TIKET & UPLOAD FILE ---
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120', // Maks 5MB
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('tickets', 'public');
        }

        $ticket = Ticket::create([
            'user_id' => Auth::id(),
            'title' => $request->title,
            'description' => $request->description,
            'priority' => $request->priority ?? 'Medium',
            'attachment' => $attachmentPath,
            'status' => 'open',
        ]);

        TicketHistory::create([
            'ticket_id' => $ticket->id,
            'user_id' => Auth::id(),
            'action' => 'Tiket Dibuat',
            'description' => 'Tiket baru berhasil dibuat.',
        ]);

        return response()->json(['success' => true, 'message' => 'Tiket berhasil dibuat', 'data' => $ticket], 201);
    }

    // --- ALUR 2: TERIMA TIKET (ADMIN) ---
    public function acceptTicket($id)
    {
        $ticket = Ticket::findOrFail($id);
        if ($ticket->status !== 'open') return response()->json(['success' => false, 'message' => 'Tiket tidak valid'], 400);

        $ticket->update(['status' => 'assign']);

        TicketHistory::create([
            'ticket_id' => $ticket->id, 'user_id' => Auth::id(),
            'action' => 'Diterima Admin', 'description' => 'Tiket masuk antrean penugasan.',
        ]);

        // Notif ke User
        $this->sendNotification($ticket->user_id, $ticket->id, 'Status Berubah', "Tiket $ticket->id telah diterima Admin.");

        return response()->json(['success' => true, 'message' => 'Tiket diterima.']);
    }

    // --- ALUR 3: ASSIGN KE HELPDESK (ADMIN) ---
    public function assignToHelpdesk(Request $request, $id)
    {
        $request->validate(['helpdesk_id' => 'required|exists:users,id']);
        $ticket = Ticket::findOrFail($id);
        $helpdesk = User::findOrFail($request->helpdesk_id);

        $ticket->update(['helpdesk_id' => $helpdesk->id, 'status' => 'in progress']);

        TicketHistory::create([
            'ticket_id' => $ticket->id, 'user_id' => Auth::id(),
            'action' => 'Ditugaskan', 'description' => "Ditugaskan kepada {$helpdesk->name}.",
        ]);

        // Notif ke User & Helpdesk
        $this->sendNotification($ticket->user_id, $ticket->id, 'Sedang Dikerjakan', "Tiket $ticket->id sedang ditangani oleh {$helpdesk->name}.");
        $this->sendNotification($helpdesk->id, $ticket->id, 'Tugas Baru', "Anda ditugaskan menangani tiket $ticket->id.");

        return response()->json(['success' => true, 'message' => 'Tiket ditugaskan.']);
    }

    // --- ALUR 4: SELESAI (HELPDESK) ---
    public function finishTicket($id)
    {
        $ticket = Ticket::findOrFail($id);
        $ticket->update(['status' => 'close']);

        TicketHistory::create([
            'ticket_id' => $ticket->id, 'user_id' => Auth::id(),
            'action' => 'Selesai', 'description' => 'Pekerjaan telah diselesaikan.',
        ]);

        // Notif ke User
        $this->sendNotification($ticket->user_id, $ticket->id, 'Tiket Selesai', "Tiket $ticket->id telah berhasil diselesaikan.");

        return response()->json(['success' => true, 'message' => 'Tiket ditutup.']);
    }

    // --- STATISTIK DASHBOARD ---
    public function statistics(Request $request)
    {
        $user = $request->user();
        $query = Ticket::query();

        if ($user->role === 'user') { $query->where('user_id', $user->id); }
        elseif ($user->role === 'helpdesk') { $query->where('helpdesk_id', $user->id); }

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $query->count(),
                'open' => (clone $query)->where('status', 'open')->count(),
                'assign' => (clone $query)->where('status', 'assign')->count(),
                'in_progress' => (clone $query)->where('status', 'in progress')->count(),
                'close' => (clone $query)->where('status', 'close')->count(),
            ]
        ]);
    }
}
