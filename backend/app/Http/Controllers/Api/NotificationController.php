<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    // Mengambil semua notifikasi milik user yang sedang login
    public function index(Request $request)
    {
        $notifications = $request->user()->notifications;
        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    // Menandai satu notifikasi telah dibaca
    public function markAsRead(Request $request, $id)
    {
        $notification = Notification::where('user_id', $request->user()->id)->findOrFail($id);
        $notification->update(['is_read' => true]);

        return response()->json(['success' => true, 'message' => 'Notifikasi ditandai dibaca']);
    }

    // Menandai semua notifikasi telah dibaca
    public function markAllAsRead(Request $request)
    {
        Notification::where('user_id', $request->user()->id)->update(['is_read' => true]);

        return response()->json(['success' => true, 'message' => 'Semua notifikasi ditandai dibaca']);
    }
}
