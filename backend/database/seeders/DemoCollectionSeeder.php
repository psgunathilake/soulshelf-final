<?php

namespace Database\Seeders;

use App\Models\Collection;
use App\Models\Media;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoCollectionSeeder extends Seeder
{
    public function seedFor(User $user): void
    {
        Collection::where('user_id', $user->id)->delete();

        $favorites = Collection::create([
            'user_id'     => $user->id,
            'name'        => 'All-time favorites',
            'description' => 'Five-star picks across books, shows, and songs.',
        ]);

        $favoriteIds = Media::where('user_id', $user->id)
            ->where('rating', 5)
            ->pluck('id');

        $favorites->media()->attach($favoriteIds);

        $current = Collection::create([
            'user_id'     => $user->id,
            'name'        => 'Currently enjoying',
            'description' => 'What I\'m actively reading and watching this week.',
        ]);

        $ongoingIds = Media::where('user_id', $user->id)
            ->where('status', 'ongoing')
            ->pluck('id');

        $current->media()->attach($ongoingIds);

        $this->command?->info("  → collections seeded: 2 (favorites: {$favoriteIds->count()} items, current: {$ongoingIds->count()} items)");
    }
}
