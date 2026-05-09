<?php

namespace Database\Seeders;

use App\Services\StatsService;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->command->info('Seeding demo account…');

        $user = (new DemoUserSeeder())
            ->setCommand($this->command)
            ->run();

        $media = new DemoMediaSeeder();
        $media->setCommand($this->command);
        $media->seedFor($user);

        $collections = new DemoCollectionSeeder();
        $collections->setCommand($this->command);
        $collections->seedFor($user);

        $journals = new DemoJournalSeeder();
        $journals->setCommand($this->command);
        $journals->seedFor($user);

        app(StatsService::class)->recompute($user);
        $this->command->info('  → stats recomputed for user '.$user->id);

        $this->command->info('Done. Login: '.DemoUserSeeder::EMAIL.' / '.DemoUserSeeder::PASSWORD);
    }
}
