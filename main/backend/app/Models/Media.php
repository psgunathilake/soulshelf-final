<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Media extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'category',
        'sub_type',
        'genre',
        'rating',
        'status',
        'cover_url',
        'reflection',
        'start_date',
        'end_date',
        'details',
    ];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'start_date' => 'date',
            'end_date' => 'date',
            'details' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function collections(): BelongsToMany
    {
        return $this->belongsToMany(Collection::class, 'collection_media')
            ->withPivot('created_at');
    }
}
