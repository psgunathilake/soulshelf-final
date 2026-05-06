<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DemoUserSeeder extends Seeder
{
    public const EMAIL    = 'demo@soulshelf.test';
    public const PASSWORD = 'Demo2026!';

    public function run(): User
    {
        $user = User::updateOrCreate(
            ['email' => self::EMAIL],
            [
                'name'              => 'Demo User',
                'password'          => self::PASSWORD,
                'email_verified_at' => Carbon::now(),
                'bio'               => 'Demo account seeded for SoulShelf walkthroughs and screenshots.',
                'photo_url'         => null,
                'header_url'        => null,
                'preferences'       => [
                    'theme'         => 'system',
                    'reminderTime'  => '20:00',
                    'showWeather'   => true,
                    'showWaterCups' => true,
                ],
                'stats'             => null,
            ]
        );

        $this->command?->info("  → user: {$user->email} (id={$user->id})");

        return $user;
    }
}
