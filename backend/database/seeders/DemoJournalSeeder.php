<?php

namespace Database\Seeders;

use App\Models\Journal;
use App\Models\Media;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DemoJournalSeeder extends Seeder
{
    public function seedFor(User $user): void
    {
        Journal::where('user_id', $user->id)->delete();

        $today = Carbon::today();

        $linkedMediaId = Media::where('user_id', $user->id)
            ->where('title', 'Project Hail Mary')
            ->value('id');

        $entries = [
            [
                'date'            => $today->copy(),
                'content'         => "Seeded today. Tested the new walkthrough flow end-to-end and it felt clean. Recommendations strip is finally pulling its weight.",
                'mood'            => 4,
                'stress'          => 2,
                'weather'         => 'sunny',
                'water_cups'      => 8,
                'todos'           => [
                    ['text' => 'Polish dashboard empty states', 'done' => true],
                    ['text' => 'Write seeder docs',              'done' => true],
                    ['text' => 'Record demo video',              'done' => false],
                ],
                'birthdays'       => [],
                'linked_media_id' => null,
            ],
            [
                'date'            => $today->copy()->subDays(1),
                'content'         => "Long debug session on the planner sync. Fixed the duplicate-entry bug — it was a stale Hive write queue, not the API. Slept badly.",
                'mood'            => 3,
                'stress'          => 4,
                'weather'         => 'cloudy',
                'water_cups'      => 5,
                'todos'           => [
                    ['text' => 'Repro the duplicate planner bug', 'done' => true],
                    ['text' => 'Add regression test',             'done' => false],
                ],
                'birthdays'       => [],
                'linked_media_id' => null,
            ],
            [
                'date'            => $today->copy()->subDays(2),
                'content'         => "Read another chapter of Project Hail Mary at lunch. Rocky's whole arc is the most charming thing I've read this year. Made progress on the recommendation engine.",
                'mood'            => 5,
                'stress'          => 1,
                'weather'         => 'sunny',
                'water_cups'      => 8,
                'todos'           => [
                    ['text' => 'Read 30 pages',           'done' => true],
                    ['text' => 'Ship recs prototype',     'done' => true],
                ],
                'birthdays'       => [],
                'linked_media_id' => $linkedMediaId,
            ],
            [
                'date'            => $today->copy()->subDays(3),
                'content'         => "Rough day. Three meetings back-to-back, no deep work. Did manage to journal so the streak survives.",
                'mood'            => 2,
                'stress'          => 4,
                'weather'         => 'rainy',
                'water_cups'      => 4,
                'todos'           => [
                    ['text' => 'Survive standup',       'done' => true],
                    ['text' => 'Eat actual lunch',      'done' => false],
                ],
                'birthdays'       => [],
                'linked_media_id' => null,
            ],
            [
                'date'            => $today->copy()->subDays(4),
                'content'         => "Quiet morning, finished the auth refactor. Phase 6 is officially shippable. Walked 4km after dinner.",
                'mood'            => 4,
                'stress'          => 2,
                'weather'         => 'sunny',
                'water_cups'      => 7,
                'todos'           => [
                    ['text' => 'Merge auth refactor PR', 'done' => true],
                    ['text' => 'Walk after dinner',      'done' => true],
                ],
                'birthdays'       => [],
                'linked_media_id' => null,
            ],
        ];

        foreach ($entries as $entry) {
            Journal::create(array_merge(['user_id' => $user->id], $entry));
        }

        $this->command?->info('  → journals seeded: '.count($entries).' entries (5-day streak)');
    }
}
