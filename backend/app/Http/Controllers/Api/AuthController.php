<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    // --- FUNGSI LOGIN ---
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($request->only('email', 'password'))) {
            /** @var \App\Models\User $user */
            $user = Auth::user();

            // --- BLOKADE AKUN NON-AKTIF ---
            if (!$user->is_active) {
                // Hapus sesi jika terlanjur login
                $user->tokens()->delete();
                return response()->json([
                    'success' => false,
                    'message' => 'Akun Anda telah dinonaktifkan oleh Admin.'
                ], 403);
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login berhasil',
                'data' => ['user' => $user, 'access_token' => $token]
            ], 200);
        }

        return response()->json(['success' => false, 'message' => 'Email atau password salah'], 401);
    }

    // --- FUNGSI REGISTER ---
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6|confirmed', // Harus ada password_confirmation di request body
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil',
            'data' => $user
        ], 201);
    }

    // --- FUNGSI LOGOUT ---
    public function logout(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $user->tokens()->where('id', $user->currentAccessToken()->id)->delete();

        return response()->json(['success' => true, 'message' => 'Logout berhasil'], 200);
    }

    // --- FUNGSI FORGOT PASSWORD ---
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        // Catatan: Ini simulasi sukses. Logika kirim email sungguhan bisa ditambahkan nanti.
        return response()->json([
            'success' => true,
            'message' => 'Tautan reset password telah dikirim jika email terdaftar.'
        ]);
    }
}
