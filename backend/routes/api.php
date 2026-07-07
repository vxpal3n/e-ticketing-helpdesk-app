<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\AdminController;
use Illuminate\Support\Facades\Route;

// --- ENDPOINT PUBLIK (Tanpa Token) ---
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']); // (Opsional jika ada fitur reset)

// --- ENDPOINT TERPROTEKSI SANCTUM ---
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // 1. DASHBOARD & STATISTIK
    Route::get('/dashboard/statistics', [TicketController::class, 'statistics']);

    // 2. MANAJEMEN TIKET
    Route::get('/tickets', [TicketController::class, 'index']);
    Route::post('/tickets', [TicketController::class, 'store']);
    Route::get('/tickets/{id}', [TicketController::class, 'show']);

    // 3. EVENT-DRIVEN STATUS
    Route::post('/tickets/{id}/accept', [TicketController::class, 'acceptTicket']);
    Route::post('/tickets/{id}/assign', [TicketController::class, 'assignToHelpdesk']);
    Route::post('/tickets/{id}/finish', [TicketController::class, 'finishTicket']);

    // 4. KOMENTAR
    Route::post('/tickets/{id}/comments', [CommentController::class, 'store']);

    // 5. NOTIFIKASI
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    // 6. FITUR KHUSUS ADMIN (Pastikan frontend membatasi akses ke sini)
    Route::get('/admin/users', [AdminController::class, 'getUsers']);
    Route::patch('/admin/users/{id}/toggle-status', [AdminController::class, 'toggleUserStatus']);
    Route::delete('/admin/tickets/{id}', [AdminController::class, 'deleteTicket']);
});
