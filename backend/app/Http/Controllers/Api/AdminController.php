<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Ticket;
use Illuminate\Support\Facades\Auth; // <-- Wajib di-import

class AdminController extends Controller
{
    // Melihat daftar semua pengguna
    public function getUsers()
    {
        $users = User::orderBy('created_at', 'desc')->get();
        return response()->json(['success' => true, 'data' => $users]);
    }

    // Mengaktifkan / Menonaktifkan Pengguna (Soft Non-Aktif)
    public function toggleUserStatus($id)
    {
        $user = User::findOrFail($id);

        // Gunakan Auth::id() agar bebas dari garis merah VSCode
        if (Auth::id() == $user->id) {
            return response()->json(['success' => false, 'message' => 'Tidak dapat menonaktifkan akun sendiri'], 403);
        }

        $user->update(['is_active' => !$user->is_active]);

        $status = $user->is_active ? 'diaktifkan' : 'dinonaktifkan';
        return response()->json(['success' => true, 'message' => "Pengguna berhasil $status"]);
    }

    // Menghapus tiket secara permanen
    public function deleteTicket($id)
    {
        $ticket = Ticket::findOrFail($id);
        $ticket->delete(); // Otomatis menghapus history & komentar

        return response()->json(['success' => true, 'message' => 'Tiket berhasil dihapus secara permanen']);
    }
}
