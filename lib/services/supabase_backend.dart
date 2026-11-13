import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/checklist_item.dart';
import '../models/dining_table.dart';
import '../models/dish.dart';
import '../models/food_order.dart';
import '../models/reservation.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/service_entry.dart';
import '../models/user.dart';
import '../utils/phone.dart';
import 'backend_config.dart';

class BackendSnapshot {
  const BackendSnapshot({
    required this.currentUser,
    required this.users,
    required this.restaurants,
    required this.tables,
    required this.dishes,
    required this.reservations,
    required this.orders,
    required this.reviews,
    required this.entries,
    required this.checklist,
  });

  final AppUser currentUser;
  final List<AppUser> users;
  final List<Restaurant> restaurants;
  final List<DiningTable> tables;
  final List<Dish> dishes;
  final List<Reservation> reservations;
  final List<FoodOrder> orders;
  final List<Review> reviews;
  final List<ServiceEntry> entries;
  final List<ChecklistItem> checklist;
}

/// Supabase auth, typed reads, and server-validated booking actions.
class SupabaseBackend {
  SupabaseBackend(this.client);

  final SupabaseClient client;

  static Future<SupabaseBackend?> initialize() async {
    BackendConfig.validate();
    if (!BackendConfig.isSupabaseConfigured) return null;
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
    return SupabaseBackend(Supabase.instance.client);
  }

  Future<AppUser?> currentProfile() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    return row == null ? null : _userFromRow(row);
  }

  Future<AppUser?> signIn(String phone, String password) async {
    await client.auth.signInWithPassword(
      phone: normalizePhone(phone),
      password: password,
    );
    return currentProfile();
  }

  Future<void> signOut() => client.auth.signOut();

  Future<BackendSnapshot?> loadSnapshot() async {
    final user = await currentProfile();
    if (user == null) return null;

    final restaurantId = user.restaurantId;
    final profileRows = restaurantId == null
        ? <Map<String, dynamic>>[await _profileRow(user.id)]
        : await client
            .from('profiles')
            .select()
            .eq('restaurant_id', restaurantId);
    final restaurantRows = await client.from('restaurants').select();
    final tableRows = await client.from('dining_tables').select();
    final dishRows = await client.from('dishes').select();
    final reservationRows = await client.from('reservations').select();
    final orderRows = await client.from('orders').select();
    final reviewRows = await client.from('reviews').select();
    final entryRows = await client.from('service_entries').select();
    final checklistRows = await client.from('checklist_items').select();

    return BackendSnapshot(
      currentUser: user,
      users: profileRows.map(_userFromRow).toList(),
      restaurants: restaurantRows.map(_restaurantFromRow).toList(),
      tables: tableRows.map(_tableFromRow).toList(),
      dishes: dishRows.map(_dishFromRow).toList(),
      reservations: reservationRows.map(_reservationFromRow).toList(),
      orders: orderRows.map(_orderFromRow).toList(),
      reviews: reviewRows.map(_reviewFromRow).toList(),
      entries: entryRows.map(_entryFromRow).toList(),
      checklist: checklistRows.map(_checklistFromRow).toList(),
    );
  }

  Future<Map<String, dynamic>> _profileRow(String id) async =>
      (await client.from('profiles').select().eq('id', id).single());

  Future<AppUser?> signUpGuest({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      phone: normalizePhone(phone),
      password: password,
      data: {'display_name': name.trim()},
    );
    if (response.session == null) return null;
    return currentProfile();
  }

  Future<AppUser?> verifyPhone(String phone, String token) async {
    await client.auth.verifyOTP(
      phone: normalizePhone(phone),
      token: token,
      type: OtpType.sms,
    );
    return currentProfile();
  }

  Future<void> resendPhoneSignupCode(String phone) => client.auth.resend(
        type: OtpType.sms,
        phone: normalizePhone(phone),
      );

  Future<String> registerRestaurant({
    required String id,
    required String name,
    required String city,
    required String address,
    required String description,
    required String cuisine,
    required String phone,
    required int openMinutes,
    required int closeMinutes,
    required int tablesCount,
  }) async {
    final result = await client.rpc('register_restaurant', params: {
      'p_restaurant_id': id,
      'p_name': name,
      'p_city': city,
      'p_address': address,
      'p_description': description,
      'p_cuisine': cuisine,
      'p_phone': normalizePhone(phone),
      'p_open_minutes': openMinutes,
      'p_close_minutes': closeMinutes,
      'p_tables_count': tablesCount,
    });
    return result as String;
  }

  Future<Reservation> createReservation({
    required String id,
    required String restaurantId,
    required String tableId,
    required DateTime start,
    required int guests,
    required String comment,
    required List<OrderItem> items,
  }) async {
    final result = await client.rpc('create_reservation', params: {
      'p_id': id,
      'p_restaurant_id': restaurantId,
      'p_table_id': tableId,
      'p_starts_at': start.toUtc().toIso8601String(),
      'p_guests': guests,
      'p_comment': comment,
      'p_items': items.map((item) => item.toJson()).toList(),
    });
    return _reservationFromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> cancelReservation(String id) async {
    await client.rpc('cancel_reservation', params: {'p_id': id});
  }

  Future<void> confirmReservation(String id) async {
    await client.rpc('confirm_reservation', params: {'p_id': id});
  }

  Future<void> seatReservation(String id) async {
    await client.rpc('seat_reservation', params: {'p_id': id});
  }

  Future<List<String>> toggleFavorite(String restaurantId) async {
    final result = await client.rpc('toggle_favorite', params: {
      'p_restaurant_id': restaurantId,
    });
    return (result as List<dynamic>).whereType<String>().toList();
  }

  AppUser _userFromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'] as String,
        name: (row['display_name'] as String?) ?? '',
        phone: (row['phone'] as String?) ?? '',
        role: UserRole.values.firstWhere(
          (role) => role.name == row['role'],
          orElse: () => UserRole.guest,
        ),
        restaurantId: row['restaurant_id'] as String?,
        salt: '',
        passwordHash: '',
        favoriteRestaurantIds:
            ((row['favorite_restaurant_ids'] as List<dynamic>?) ?? const [])
                .whereType<String>()
                .toList(),
      );

  Restaurant _restaurantFromRow(Map<String, dynamic> row) =>
      Restaurant.fromJson({
        'id': row['id'],
        'ownerId': row['owner_id'],
        'name': row['name'],
        'city': row['city'],
        'address': row['address'],
        'description': row['description'],
        'cuisine': row['cuisine'],
        'phone': row['phone'],
        'openMinutes': row['open_minutes'],
        'closeMinutes': row['close_minutes'],
        'photos': row['photos'],
      });

  DiningTable _tableFromRow(Map<String, dynamic> row) =>
      DiningTable.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'number': row['number'],
        'seats': row['seats'],
        'zone': row['zone'],
        'occupied': row['occupied'],
        'guests': row['guests'],
        'since': row['since']?.toString(),
      });

  Dish _dishFromRow(Map<String, dynamic> row) => Dish.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'name': row['name'],
        'price': row['price'],
        'category': row['category'],
        'description': row['description'],
        'available': row['available'],
      });

  Reservation _reservationFromRow(Map<String, dynamic> row) =>
      Reservation.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'tableId': row['table_id'],
        'userId': row['user_id'],
        'guestName': row['guest_name'],
        'phone': row['phone'],
        'start': row['starts_at'],
        'guests': row['guests'],
        'status': row['status'],
        'comment': row['comment'],
        'createdAt': row['created_at'],
      });

  FoodOrder _orderFromRow(Map<String, dynamic> row) => FoodOrder.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'tableId': row['table_id'],
        'reservationId': row['reservation_id'],
        'createdById': row['created_by_id'],
        'createdByName': row['created_by_name'],
        'items': row['items'],
        'status': row['status'],
        'comment': row['comment'],
        'createdAt': row['created_at'],
        'forTime': row['for_time'],
        'paidAt': row['paid_at'],
      });

  Review _reviewFromRow(Map<String, dynamic> row) => Review.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'reservationId': row['reservation_id'],
        'userId': row['user_id'],
        'userName': row['user_name'],
        'stars': row['stars'],
        'text': row['text'],
        'createdAt': row['created_at'],
      });

  ServiceEntry _entryFromRow(Map<String, dynamic> row) =>
      ServiceEntry.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'title': row['title'],
        'description': row['description'],
        'workerName': row['worker_name'],
        'workerRole': row['worker_role'],
        'category': row['category'],
        'date': row['entry_date'],
        'resolved': row['resolved'],
      });

  ChecklistItem _checklistFromRow(Map<String, dynamic> row) =>
      ChecklistItem.fromJson({
        'id': row['id'],
        'restaurantId': row['restaurant_id'],
        'title': row['title'],
        'type': row['type'],
        'doneBy': row['done_by'],
        'doneAt': row['done_at'],
      });
}
