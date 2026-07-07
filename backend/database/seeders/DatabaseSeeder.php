<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Bikin Akun Admin
        User::create([
            'name' => 'Pak Admin',
            'email' => 'admin@mail.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);

        // Bikin Akun Helpdesk
        User::create([
            'name' => 'Mas Helpdesk',
            'email' => 'helpdesk@mail.com',
            'password' => Hash::make('password123'),
            'role' => 'helpdesk',
        ]);

        // Bikin Akun User (Mahasiswa/Karyawan)
        User::create([
            'name' => 'Kak User',
            'email' => 'user@mail.com',
            'password' => Hash::make('password123'),
            'role' => 'user',
        ]);
    }
}
