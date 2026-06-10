# Worker Reviews API — Laravel Backend Specification

This document describes the endpoint required by the **Dllni Cleaning Owner App** (worker mobile app) to fetch customer reviews and ratings for the authenticated worker.

---

## Endpoint Overview

| Property | Value |
|----------|-------|
| **Method** | `GET` |
| **URL** | `/api/v1/cleaning/worker/reviews` |
| **Auth** | Bearer token (`Authorization: Bearer {token}`) |
| **Guard** | Worker / cleaning worker guard (same as other `/api/v1/cleaning/worker/*` endpoints) |

---

## Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Current page number |
| `perPage` | integer | No | `20` | Items per page |

Example:

```
GET /api/v1/cleaning/worker/reviews?page=1&perPage=20
```

---

## Success Response (200)

```json
{
  "data": [
    {
      "id": 1,
      "customerName": "محمد العتيبي",
      "rating": 5,
      "comment": "خدمة ممتازة والعامل محترف جداً.",
      "createdAt": "2026-05-28T10:30:00.000000Z"
    },
    {
      "id": 2,
      "customerName": "سارة الحربي",
      "rating": 4,
      "comment": "عمل جيد بشكل عام.",
      "createdAt": "2026-05-22T14:15:00.000000Z"
    }
  ],
  "meta": {
    "averageRating": 4.4,
    "totalCount": 12,
    "currentPage": 1,
    "lastPage": 1,
    "perPage": 20
  }
}
```

### Field Mapping (Flutter model)

The mobile app model is defined in:

`lib/features/profile/data/models/fetch_worker_reviews_model.dart`

| JSON field | Flutter field | Type | Notes |
|------------|---------------|------|-------|
| `data[].id` | `id` | int | Review primary key |
| `data[].customerName` | `customerName` | string | Customer display name |
| `data[].rating` | `rating` | number | 1–5 scale |
| `data[].comment` | `comment` | string | Optional review text |
| `data[].createdAt` | `createdAt` | string (ISO 8601) | Review creation date |
| `meta.averageRating` | `averageRating` | number | Average of all worker reviews |
| `meta.totalCount` | `totalCount` | int | Total reviews count |
| `meta.currentPage` | `currentPage` | int | Pagination |
| `meta.lastPage` | `lastPage` | int | Pagination |
| `meta.perPage` | `perPage` | int | Pagination |

> **Note:** The Flutter parser also accepts snake_case variants (`customer_name`, `created_at`, `average_rating`, `total_count`, etc.) for compatibility.

---

## Error Responses

Follow the same error format used by existing cleaning worker endpoints:

```json
{
  "message": "Unauthenticated."
}
```

| Status | When |
|--------|------|
| `401` | Missing or invalid token |
| `403` | User is not a cleaning worker |
| `422` | Invalid query parameters |
| `500` | Server error |

---

## Suggested Database Schema

If reviews are not yet stored, suggested table:

```sql
CREATE TABLE cleaning_booking_reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cleaning_booking_id BIGINT UNSIGNED NOT NULL,
    worker_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL COMMENT '1-5',
    comment TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    UNIQUE KEY unique_booking_review (cleaning_booking_id),
    INDEX idx_worker_id (worker_id),
    INDEX idx_customer_id (customer_id)
);
```

---

## Laravel Implementation Guide

### 1. Route (`routes/api.php`)

Register inside the same middleware group as other worker routes:

```php
Route::middleware(['auth:sanctum', 'worker'])->prefix('v1/cleaning/worker')->group(function () {
    // ... existing routes
    Route::get('reviews', [WorkerReviewController::class, 'index']);
});
```

### 2. Controller

```php
namespace App\Http\Controllers\Api\V1\Cleaning\Worker;

use App\Http\Controllers\Controller;
use App\Http\Resources\WorkerReviewResource;
use Illuminate\Http\Request;

class WorkerReviewController extends Controller
{
    public function index(Request $request)
    {
        $worker = $request->user()->worker; // adjust to your auth model

        $perPage = min((int) $request->query('perPage', 20), 50);
        $page = max((int) $request->query('page', 1), 1);

        $query = $worker->reviews()
            ->with('customer:id,name')
            ->latest();

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);

        $averageRating = $worker->reviews()->avg('rating') ?? 0;

        return WorkerReviewResource::collection($paginator)->additional([
            'meta' => [
                'averageRating' => round($averageRating, 1),
                'totalCount' => $paginator->total(),
                'currentPage' => $paginator->currentPage(),
                'lastPage' => $paginator->lastPage(),
                'perPage' => $paginator->perPage(),
            ],
        ]);
    }
}
```

### 3. API Resource

```php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class WorkerReviewResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'customerName' => $this->customer?->name,
            'rating' => (float) $this->rating,
            'comment' => $this->comment,
            'createdAt' => $this->created_at?->toIso8601String(),
        ];
    }
}
```

### 4. Worker Model Relationship

```php
public function reviews()
{
    return $this->hasMany(CleaningBookingReview::class, 'worker_id');
}
```

---

## Mobile App Integration (already prepared)

The Flutter app is wired and ready. Once this endpoint is live:

1. `ProfileRemoteDataSource.fetchWorkerReviews()` calls `GET /api/v1/cleaning/worker/reviews`
2. `FetchWorkerReviewsUseCase` → `ProfileRepo` → `ProfileBloc`
3. `WorkerReviewsScreen` dispatches `FetchWorkerReviewsEvent` on open
4. When API returns data, mock data is replaced automatically

No mobile changes are needed after the backend is deployed — only remove mock fallback in `worker_reviews_screen.dart` if desired once API is stable.

---

## Testing Checklist

- [ ] Authenticated worker receives only their own reviews
- [ ] Pagination works with `page` and `perPage`
- [ ] `meta.averageRating` reflects all reviews (not just current page)
- [ ] `meta.totalCount` matches total review count
- [ ] Empty state returns `{ "data": [], "meta": { "averageRating": 0, "totalCount": 0, ... } }`
- [ ] Unauthenticated request returns `401`
