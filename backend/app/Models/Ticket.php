<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id', 'helpdesk_id', 'title', 'description', 'priority', 'attachment', 'status',
    ];

    // Fungsi otomatis untuk membuat Custom ID (Contoh: TK-20260706-001)
    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            $date = now()->format('Ymd');
            $latest = self::whereDate('created_at', now()->toDateString())->count();
            $number = str_pad($latest + 1, 3, '0', STR_PAD_LEFT);
            $model->id = 'TK-' . $date . '-' . $number;
        });
    }

    public function user() { return $this->belongsTo(User::class, 'user_id'); }
    public function helpdesk() { return $this->belongsTo(User::class, 'helpdesk_id'); }
    public function histories() { return $this->hasMany(TicketHistory::class)->orderBy('created_at', 'desc'); }
    public function comments() { return $this->hasMany(TicketComment::class)->orderBy('created_at', 'asc'); }
}
