<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Planner extends Model
{
    protected $fillable = [
        'user_id',
        'date',
        'schedule',
        'priorities',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'schedule' => 'array',
            'priorities' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
