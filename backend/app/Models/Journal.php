<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Journal extends Model
{
    protected $fillable = [
        'user_id',
        'date',
        'content',
        'mood',
        'stress',
        'weather',
        'water_cups',
        'todos',
        'birthdays',
        'linked_media_id',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'mood' => 'integer',
            'stress' => 'integer',
            'water_cups' => 'integer',
            'todos' => 'array',
            'birthdays' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function linkedMedia(): BelongsTo
    {
        return $this->belongsTo(Media::class, 'linked_media_id');
    }
}
