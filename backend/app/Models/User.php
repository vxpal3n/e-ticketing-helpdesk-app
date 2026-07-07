<?php

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name', 'email', 'password', 'role', 'is_active',
    ];

    protected $hidden = [
        'password', 'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function tickets() { return $this->hasMany(Ticket::class, 'user_id'); }
    public function assignedTickets() { return $this->hasMany(Ticket::class, 'helpdesk_id'); }
    public function comments() { return $this->hasMany(TicketComment::class); }
    public function notifications() { return $this->hasMany(Notification::class)->orderBy('created_at', 'desc'); }
}
