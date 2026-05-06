<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->char('pin_hash', 64)->nullable()->after('password');
            $table->string('photo_url', 500)->nullable()->after('pin_hash');
            $table->string('header_url', 500)->nullable()->after('photo_url');
            $table->text('bio')->nullable()->after('header_url');
            $table->json('preferences')->nullable()->after('bio');
            $table->json('stats')->nullable()->after('preferences');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'pin_hash',
                'photo_url',
                'header_url',
                'bio',
                'preferences',
                'stats',
            ]);
        });
    }
};
