<?php

namespace App\Policies;

use App\Models\Planner;
use App\Models\User;

class PlannerPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Planner $planner): bool
    {
        return $user->id === $planner->user_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Planner $planner): bool
    {
        return $user->id === $planner->user_id;
    }

    public function delete(User $user, Planner $planner): bool
    {
        return $user->id === $planner->user_id;
    }
}
