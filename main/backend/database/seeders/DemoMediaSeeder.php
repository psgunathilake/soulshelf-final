<?php

namespace Database\Seeders;

use App\Models\Media;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DemoMediaSeeder extends Seeder
{
    public function seedFor(User $user): void
    {
        Media::where('user_id', $user->id)->delete();

        $today = Carbon::today();

        $rows = array_merge(
            $this->books($user, $today),
            $this->shows($user, $today),
            $this->songs($user, $today),
        );

        foreach ($rows as $row) {
            Media::create($row);
        }

        $this->command?->info('  → media seeded: '.count($rows).' rows for user '.$user->id);
    }

    private function books(User $user, Carbon $today): array
    {
        return [
            [
                'user_id'    => $user->id,
                'title'      => 'The Pragmatic Programmer',
                'category'   => 'book',
                'genre'      => 'Programming',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Pragmatism over dogma — the chapter on tracer bullets reshaped how I prototype.',
                'start_date' => $today->copy()->subDays(60),
                'end_date'   => $today->copy()->subDays(20),
                'details'    => ['author' => 'Andrew Hunt, David Thomas', 'pages' => 352],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Atomic Habits',
                'category'   => 'book',
                'genre'      => 'Self-Help',
                'rating'     => 4,
                'status'     => 'completed',
                'reflection' => 'Tiny systems compound. Loved the "two-minute rule" for breaking inertia.',
                'start_date' => $today->copy()->subDays(120),
                'end_date'   => $today->copy()->subDays(90),
                'details'    => ['author' => 'James Clear', 'pages' => 320],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Sapiens',
                'category'   => 'book',
                'genre'      => 'History',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Reframes the human story around shared fictions — mind-expanding.',
                'start_date' => $today->copy()->subDays(180),
                'end_date'   => $today->copy()->subDays(150),
                'details'    => ['author' => 'Yuval Noah Harari', 'pages' => 464],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Project Hail Mary',
                'category'   => 'book',
                'genre'      => 'Sci-Fi',
                'rating'     => 5,
                'status'     => 'ongoing',
                'reflection' => 'Halfway through — Rocky is the best alien friendship in modern sci-fi.',
                'start_date' => $today->copy()->subDays(10),
                'end_date'   => null,
                'details'    => ['author' => 'Andy Weir', 'pages' => 496],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Clean Code',
                'category'   => 'book',
                'genre'      => 'Programming',
                'rating'     => 0,
                'status'     => 'planned',
                'reflection' => null,
                'start_date' => null,
                'end_date'   => null,
                'details'    => ['author' => 'Robert C. Martin', 'pages' => 464],
            ],
        ];
    }

    private function shows(User $user, Carbon $today): array
    {
        return [
            [
                'user_id'    => $user->id,
                'title'      => 'Breaking Bad',
                'category'   => 'show',
                'sub_type'   => 'tv_show',
                'genre'      => 'Drama',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Tightest character arc on television. "Ozymandias" is unmatched.',
                'start_date' => $today->copy()->subDays(200),
                'end_date'   => $today->copy()->subDays(80),
                'details'    => ['seasons' => 5, 'episodes' => 62],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Spirited Away',
                'category'   => 'show',
                'sub_type'   => 'movie',
                'genre'      => 'Animation',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Studio Ghibli at its peak. Watched on a quiet Sunday and didn\'t move once.',
                'start_date' => $today->copy()->subDays(45),
                'end_date'   => $today->copy()->subDays(45),
                'details'    => ['runtime_minutes' => 125, 'director' => 'Hayao Miyazaki'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Attack on Titan',
                'category'   => 'show',
                'sub_type'   => 'anime',
                'genre'      => 'Action',
                'rating'     => 4,
                'status'     => 'ongoing',
                'reflection' => 'Final season hits hard — the moral ambiguity is the point.',
                'start_date' => $today->copy()->subDays(30),
                'end_date'   => null,
                'details'    => ['seasons' => 4, 'episodes' => 87],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Inception',
                'category'   => 'show',
                'sub_type'   => 'movie',
                'genre'      => 'Sci-Fi',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Still spins. Hans Zimmer\'s score does half the storytelling.',
                'start_date' => $today->copy()->subDays(15),
                'end_date'   => $today->copy()->subDays(15),
                'details'    => ['runtime_minutes' => 148, 'director' => 'Christopher Nolan'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Severance',
                'category'   => 'show',
                'sub_type'   => 'tv_show',
                'genre'      => 'Mystery',
                'rating'     => 0,
                'status'     => 'planned',
                'reflection' => null,
                'start_date' => null,
                'end_date'   => null,
                'details'    => ['seasons' => 2, 'episodes' => 19],
            ],
        ];
    }

    private function songs(User $user, Carbon $today): array
    {
        return [
            [
                'user_id'    => $user->id,
                'title'      => 'Bohemian Rhapsody',
                'category'   => 'song',
                'genre'      => 'Rock',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Six minutes of unfiltered ambition — every section earns its place.',
                'start_date' => $today->copy()->subDays(7),
                'end_date'   => $today->copy()->subDays(7),
                'details'    => ['artist' => 'Queen', 'album' => 'A Night at the Opera'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Blinding Lights',
                'category'   => 'song',
                'genre'      => 'Pop',
                'rating'     => 4,
                'status'     => 'completed',
                'reflection' => 'Synthwave revival done right — perfect driving song.',
                'start_date' => $today->copy()->subDays(5),
                'end_date'   => $today->copy()->subDays(5),
                'details'    => ['artist' => 'The Weeknd', 'album' => 'After Hours'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Take Five',
                'category'   => 'song',
                'genre'      => 'Jazz',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Default coding soundtrack. 5/4 time signature still feels effortless.',
                'start_date' => $today->copy()->subDays(3),
                'end_date'   => $today->copy()->subDays(3),
                'details'    => ['artist' => 'Dave Brubeck Quartet', 'album' => 'Time Out'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Lose Yourself',
                'category'   => 'song',
                'genre'      => 'Hip-Hop',
                'rating'     => 4,
                'status'     => 'completed',
                'reflection' => 'Deadline-day adrenaline in three minutes.',
                'start_date' => $today->copy()->subDays(2),
                'end_date'   => $today->copy()->subDays(2),
                'details'    => ['artist' => 'Eminem', 'album' => '8 Mile Soundtrack'],
            ],
            [
                'user_id'    => $user->id,
                'title'      => 'Clair de Lune',
                'category'   => 'song',
                'genre'      => 'Classical',
                'rating'     => 5,
                'status'     => 'completed',
                'reflection' => 'Late-night journal soundtrack. Pure quiet.',
                'start_date' => $today->copy()->subDays(1),
                'end_date'   => $today->copy()->subDays(1),
                'details'    => ['artist' => 'Claude Debussy', 'album' => 'Suite bergamasque'],
            ],
        ];
    }
}
