<?php

namespace App\Services;

use App\Models\Journal;
use App\Models\Media;
use App\Models\Planner;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class StatsService
{
    public function recompute(User $user): array
    {
        $stats = [
            'mediaCount'      => $this->mediaCount($user),
            'mediaByCategory' => $this->mediaByCategory($user),
            'mediaByStatus'   => $this->mediaByStatus($user),
            'journalCount'    => $this->journalCount($user),
            'streak'          => $this->streak($user),
            'lastActiveDate'  => $this->lastActiveDate($user),
            'recomputedAt'    => now()->toIso8601String(),
        ];

        $user->forceFill(['stats' => $stats])->save();

        return $stats;
    }

    private function mediaCount(User $user): int
    {
        return Media::where('user_id', $user->id)->count();
    }

    private function mediaByCategory(User $user): array
    {
        $counts = Media::where('user_id', $user->id)
            ->groupBy('category')
            ->select('category', DB::raw('COUNT(*) as c'))
            ->pluck('c', 'category')
            ->map(fn ($v) => (int) $v)
            ->all();

        return array_merge(['book' => 0, 'song' => 0, 'show' => 0], $counts);
    }

    private function mediaByStatus(User $user): array
    {
        $counts = Media::where('user_id', $user->id)
            ->groupBy('status')
            ->select('status', DB::raw('COUNT(*) as c'))
            ->pluck('c', 'status')
            ->map(fn ($v) => (int) $v)
            ->all();

        return array_merge(['planned' => 0, 'ongoing' => 0, 'completed' => 0], $counts);
    }

    private function journalCount(User $user): int
    {
        return Journal::where('user_id', $user->id)->count();
    }

    private function streak(User $user): int
    {
        $set = Journal::where('user_id', $user->id)
            ->orderByDesc('date')
            ->pluck('date')
            ->map(fn ($d) => $d instanceof Carbon ? $d->toDateString() : substr((string) $d, 0, 10))
            ->flip();

        $cursor = Carbon::today();
        $count  = 0;

        while ($set->has($cursor->toDateString())) {
            $count++;
            $cursor->subDay();
        }

        return $count;
    }

    private function lastActiveDate(User $user): ?string
    {
        $journalMax = Journal::where('user_id', $user->id)->max('date');
        $plannerMax = Planner::where('user_id', $user->id)->max('date');
        $mediaMax   = Media::where('user_id', $user->id)->max('updated_at');

        $candidates = array_filter([
            $journalMax ? $this->toDateString($journalMax) : null,
            $plannerMax ? $this->toDateString($plannerMax) : null,
            $mediaMax   ? $this->toDateString($mediaMax)   : null,
        ]);

        if (empty($candidates)) {
            return null;
        }

        rsort($candidates);

        return $candidates[0];
    }

    private function toDateString(mixed $d): string
    {
        return $d instanceof Carbon ? $d->toDateString() : substr((string) $d, 0, 10);
    }
}
