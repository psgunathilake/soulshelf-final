<?php

namespace App\Providers;

use App\Models\Collection;
use App\Models\Journal;
use App\Models\Media;
use App\Models\Planner;
use App\Policies\CollectionPolicy;
use App\Policies\JournalPolicy;
use App\Policies\MediaPolicy;
use App\Policies\PlannerPolicy;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Force generated URLs (signed verification links, password-reset
        // links, storage URLs) to use APP_URL as their root regardless of
        // the request's host. Without this, mobile-app signups (where the
        // request hits 10.0.2.2:8000 from the Android emulator) embed that
        // unreachable host in emails delivered to a desktop browser.
        URL::forceRootUrl(config('app.url'));

        Gate::policy(Media::class, MediaPolicy::class);
        Gate::policy(Journal::class, JournalPolicy::class);
        Gate::policy(Planner::class, PlannerPolicy::class);
        Gate::policy(Collection::class, CollectionPolicy::class);

        VerifyEmail::createUrlUsing(function ($notifiable) {
            return URL::temporarySignedRoute(
                'verification.verify',
                Carbon::now()->addMinutes((int) config('auth.verification.expire', 60)),
                [
                    'id'   => $notifiable->getKey(),
                    'hash' => sha1($notifiable->getEmailForVerification()),
                ]
            );
        });

        // Password-reset link points to a simple landing page; the
        // mobile app will eventually intercept this URL via deep link.
        ResetPassword::createUrlUsing(function ($notifiable, string $token) {
            return config('app.url') . '/reset-password?' . http_build_query([
                'token' => $token,
                'email' => $notifiable->getEmailForPasswordReset(),
            ]);
        });
    }
}
