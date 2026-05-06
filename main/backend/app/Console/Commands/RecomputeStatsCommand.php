<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\StatsService;
use Illuminate\Console\Command;

class RecomputeStatsCommand extends Command
{
    protected $signature = 'stats:recompute {--user-id= : Recompute for a single user only}';

    protected $description = 'Recompute users.stats from source tables (media/journals/planners)';

    public function handle(StatsService $stats): int
    {
        $query = User::query();
        if ($id = $this->option('user-id')) {
            $query->where('id', $id);
        }

        $users = $query->get();

        if ($users->isEmpty()) {
            $this->warn('No users matched.');
            return self::SUCCESS;
        }

        $rows = [];
        foreach ($users as $user) {
            $result = $stats->recompute($user);
            $rows[] = [
                $user->id,
                $user->email,
                $result['mediaCount'],
                $result['journalCount'],
                $result['streak'],
                $result['lastActiveDate'] ?? '—',
            ];
        }

        $this->table(
            ['id', 'email', 'mediaCount', 'journalCount', 'streak', 'lastActiveDate'],
            $rows,
        );

        $this->info("Recomputed stats for {$users->count()} user(s).");

        return self::SUCCESS;
    }
}
