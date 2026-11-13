import '../constants.dart';
import '../models/checklist_item.dart';
import '../models/dining_table.dart';
import '../models/dish.dart';
import '../models/food_order.dart';
import '../models/reservation.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/service_entry.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/password.dart';
import '../utils/phone.dart';
import 'seed_data.dart';

/// Все данные приложения и вся бизнес-логика.
/// Сейчас данные лежат на телефоне (SharedPreferences). Чтобы перейти на
/// сервер (Firebase и т.п.), нужно заменить только этот файл — экраны
/// работают через его методы.
class AppRepository {
  AppRepository(this._store);

  final StorageService _store;

  List<AppUser> users = [];
  List<Restaurant> restaurants = [];
  List<DiningTable> tables = [];
  List<Dish> dishes = [];
  List<Reservation> reservations = [];
  List<FoodOrder> orders = [];
  List<Review> reviews = [];
  List<ServiceEntry> entries = [];
  List<ChecklistItem> checklist = [];

  static int _counter = 0;

  /// Уникальный id.
  String newId() => '${DateTime.now().microsecondsSinceEpoch}${_counter++}';

  // ===================== загрузка и сохранение =====================

  Future<void> load() async {
    users = _store.readList('users', AppUser.fromJson);
    restaurants = _store.readList('restaurants', Restaurant.fromJson);
    tables = _store.readList('tables', DiningTable.fromJson);
    dishes = _store.readList('dishes', Dish.fromJson);
    reservations = _store.readList('reservations', Reservation.fromJson);
    orders = _store.readList('orders', FoodOrder.fromJson);
    reviews = _store.readList('reviews', Review.fromJson);
    entries = _store.readList('entries', ServiceEntry.fromJson);
    checklist = _store.readList('checklist', ChecklistItem.fromJson);

    if (kSeedDemoData && users.isEmpty && restaurants.isEmpty) {
      seedDemoData(this);
      await saveAll();
    }
  }

  Future<void> saveUsers() =>
      _store.writeList('users', users.map((e) => e.toJson()).toList());
  Future<void> saveRestaurants() => _store.writeList(
      'restaurants', restaurants.map((e) => e.toJson()).toList());
  Future<void> saveTables() =>
      _store.writeList('tables', tables.map((e) => e.toJson()).toList());
  Future<void> saveDishes() =>
      _store.writeList('dishes', dishes.map((e) => e.toJson()).toList());
  Future<void> saveReservations() => _store.writeList(
      'reservations', reservations.map((e) => e.toJson()).toList());
  Future<void> saveOrders() =>
      _store.writeList('orders', orders.map((e) => e.toJson()).toList());
  Future<void> saveReviews() =>
      _store.writeList('reviews', reviews.map((e) => e.toJson()).toList());
  Future<void> saveEntries() =>
      _store.writeList('entries', entries.map((e) => e.toJson()).toList());
  Future<void> saveChecklist() =>
      _store.writeList('checklist', checklist.map((e) => e.toJson()).toList());

  Future<void> saveAll() async {
    await saveUsers();
    await saveRestaurants();
    await saveTables();
    await saveDishes();
    await saveReservations();
    await saveOrders();
    await saveReviews();
    await saveEntries();
    await saveChecklist();
  }

  // ===================== сессия =====================

  AppUser? restoreSession() {
    final id = _store.readString('session_user');
    if (id == null) return null;
    return userById(id);
  }

  Future<void> saveSession(String userId) =>
      _store.writeString('session_user', userId);

  Future<void> clearSession() => _store.remove('session_user');

  // ===================== поиск по id =====================

  AppUser? userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  bool isFavorite(String userId, String restaurantId) =>
      userById(userId)?.favoriteRestaurantIds.contains(restaurantId) ?? false;

  Future<void> toggleFavorite(String userId, String restaurantId) async {
    final user = userById(userId);
    if (user == null || restaurantById(restaurantId) == null) return;

    final favorites = [...user.favoriteRestaurantIds];
    if (!favorites.remove(restaurantId)) favorites.add(restaurantId);
    _replace(
      users,
      (AppUser item) => item.id == userId,
      user.copyWith(favoriteRestaurantIds: favorites),
    );
    await saveUsers();
  }

  AppUser? userByPhone(String phone) {
    final p = normalizePhone(phone);
    for (final u in users) {
      if (u.phone == p) return u;
    }
    return null;
  }

  Restaurant? restaurantById(String id) {
    for (final r in restaurants) {
      if (r.id == id) return r;
    }
    return null;
  }

  DiningTable? tableById(String id) {
    for (final t in tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  Dish? dishById(String id) {
    for (final d in dishes) {
      if (d.id == id) return d;
    }
    return null;
  }

  Reservation? reservationById(String id) {
    for (final r in reservations) {
      if (r.id == id) return r;
    }
    return null;
  }

  FoodOrder? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Заменяет элемент списка на новый (по условию).
  void _replace<T>(List<T> list, bool Function(T item) test, T replacement) {
    final index = list.indexWhere(test);
    if (index != -1) list[index] = replacement;
  }

  // ===================== выборки =====================

  /// Рестораны города: сначала с лучшим рейтингом.
  List<Restaurant> restaurantsIn(String city) {
    final list = restaurants.where((r) => r.city == city).toList();
    list.sort((a, b) => ratingOf(b.id).compareTo(ratingOf(a.id)));
    return list;
  }

  List<DiningTable> tablesOf(String restaurantId) {
    final list = tables.where((t) => t.restaurantId == restaurantId).toList();
    list.sort((a, b) => a.number.compareTo(b.number));
    return list;
  }

  List<Dish> dishesOf(String restaurantId) {
    return dishes.where((d) => d.restaurantId == restaurantId).toList();
  }

  List<Reservation> reservationsOf(String restaurantId) {
    final list =
        reservations.where((r) => r.restaurantId == restaurantId).toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  List<Reservation> reservationsOfUser(String userId) {
    final list = reservations.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  List<FoodOrder> ordersOf(String restaurantId) {
    final list = orders.where((o) => o.restaurantId == restaurantId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Предзаказ попадает на кухню только после подтверждения брони.
  bool _visibleToKitchen(FoodOrder order) {
    final reservationId = order.reservationId;
    if (reservationId == null) return true;
    final reservation = reservationById(reservationId);
    if (reservation == null) return false;
    return reservation.status == ReservationStatus.confirmed ||
        reservation.status == ReservationStatus.seated ||
        reservation.status == ReservationStatus.completed;
  }

  /// Заказы, которые должен видеть персонал ресторана.
  List<FoodOrder> staffOrdersOf(String restaurantId) {
    return ordersOf(restaurantId).where(_visibleToKitchen).toList();
  }

  FoodOrder? orderOfReservation(String reservationId) {
    for (final o in orders) {
      if (o.reservationId == reservationId) return o;
    }
    return null;
  }

  List<Review> reviewsOf(String restaurantId) {
    final list = reviews.where((r) => r.restaurantId == restaurantId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Средняя оценка ресторана (0, если отзывов нет).
  double ratingOf(String restaurantId) {
    final list = reviewsOf(restaurantId);
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (s, r) => s + r.stars);
    return sum / list.length;
  }

  List<AppUser> staffOf(String restaurantId) {
    return users.where((u) => u.restaurantId == restaurantId).toList();
  }

  List<ServiceEntry> entriesOf(String restaurantId) {
    final list = entries.where((e) => e.restaurantId == restaurantId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<ChecklistItem> checklistOf(String restaurantId, ChecklistType type) {
    return checklist
        .where((i) => i.restaurantId == restaurantId && i.type == type)
        .toList();
  }

  // ===================== столы =====================

  /// Состояние стола прямо сейчас.
  TableStatus statusOf(DiningTable table) {
    if (table.occupied) return TableStatus.occupied;
    final now = DateTime.now();
    final soon = now.add(const Duration(minutes: 60));
    for (final r in reservations) {
      final waiting = r.status == ReservationStatus.pending ||
          r.status == ReservationStatus.confirmed;
      if (r.tableId == table.id &&
          waiting &&
          r.start.isBefore(soon) &&
          r.end.isAfter(now)) {
        return TableStatus.reserved;
      }
    }
    return TableStatus.free;
  }

  /// Ближайшая ожидающая или подтверждённая бронь стола.
  Reservation? nextReservationOf(String tableId) {
    final now = DateTime.now();
    Reservation? best;
    for (final r in reservations) {
      final waiting = r.status == ReservationStatus.pending ||
          r.status == ReservationStatus.confirmed;
      if (r.tableId != tableId || !waiting || !r.end.isAfter(now)) continue;
      if (best == null || r.start.isBefore(best.start)) best = r;
    }
    return best;
  }

  int tablesCount(String restaurantId, TableStatus status) {
    return tablesOf(restaurantId).where((t) => statusOf(t) == status).length;
  }

  int guestsNow(String restaurantId) {
    return tablesOf(restaurantId)
        .where((t) => t.occupied)
        .fold(0, (sum, t) => sum + t.guests);
  }

  /// Свободен ли стол на время [start, start + 2 часа).
  bool isTableFree(String tableId, DateTime start) {
    final table = tableById(tableId);
    if (table == null) return false;

    final end = start.add(reservationDuration);
    for (final r in reservations) {
      if (r.tableId != tableId || !r.status.isActive) continue;
      if (start.isBefore(r.end) && r.start.isBefore(end)) return false;
    }

    // Если гости сидят прямо сейчас, ближайшие 2 часа стол недоступен.
    final blockedUntil = DateTime.now().add(reservationDuration);
    if (table.occupied && start.isBefore(blockedUntil)) return false;
    return true;
  }

  Future<String?> addTable({
    required String restaurantId,
    required int number,
    required int seats,
    required TableZone zone,
  }) async {
    final exists =
        tablesOf(restaurantId).any((t) => t.number == number);
    if (exists) return 'Стол с номером $number уже есть';
    tables.add(DiningTable(
      id: newId(),
      restaurantId: restaurantId,
      number: number,
      seats: seats,
      zone: zone,
    ));
    await saveTables();
    return null;
  }

  Future<String?> updateTable({
    required String tableId,
    required int number,
    required int seats,
    required TableZone zone,
  }) async {
    final table = tableById(tableId);
    if (table == null) return 'Стол не найден';
    final clash = tablesOf(table.restaurantId)
        .any((t) => t.number == number && t.id != tableId);
    if (clash) return 'Стол с номером $number уже есть';
    _replace(tables, (DiningTable t) => t.id == tableId,
        table.copyWith(number: number, seats: seats, zone: zone));
    await saveTables();
    return null;
  }

  Future<String?> deleteTable(String tableId) async {
    final table = tableById(tableId);
    if (table == null) return null;
    if (table.occupied) return 'За столом сейчас сидят гости';
    final busy = reservations
        .any((r) => r.tableId == tableId && r.status.isActive);
    if (busy) return 'У стола есть активные брони';
    tables.removeWhere((t) => t.id == tableId);
    await saveTables();
    return null;
  }

  /// Посадить гостей (без брони).
  Future<String?> seatTable(String tableId, int guests) async {
    final table = tableById(tableId);
    if (table == null) return 'Стол не найден';
    if (guests < 1) return 'Укажите количество гостей';
    if (guests > table.seats) return 'За этим столом только ${table.seats} мест';
    if (table.occupied) return 'Этот стол уже занят';
    _replace(tables, (DiningTable t) => t.id == tableId, table.seated(guests));
    await saveTables();
    return null;
  }

  /// Освободить стол. Нельзя, пока есть неоплаченные заказы.
  Future<String?> freeTable(String tableId) async {
    final table = tableById(tableId);
    if (table == null) return 'Стол не найден';

    final hasOpenOrders = orders.any((o) {
      if (o.tableId != tableId || !o.status.isOpen) return false;
      final rid = o.reservationId;
      if (rid == null) return true;
      return reservationById(rid)?.status == ReservationStatus.seated;
    });
    if (hasOpenOrders) {
      return 'Сначала закройте заказы стола (оплата или отмена)';
    }

    _replace(tables, (DiningTable t) => t.id == tableId, table.freed());
    for (var i = 0; i < reservations.length; i++) {
      final r = reservations[i];
      if (r.tableId == tableId && r.status == ReservationStatus.seated) {
        reservations[i] = r.copyWith(status: ReservationStatus.completed);
      }
    }
    await saveTables();
    await saveReservations();
    return null;
  }

  // ===================== брони =====================

  /// Время, на которое можно записаться в выбранный день.
  List<DateTime> slotsFor(Restaurant restaurant, DateTime day) {
    final open = restaurant.openMinutes;
    var close = restaurant.closeMinutes;
    if (close <= open) close += 24 * 60; // работает за полночь

    final base = DateTime(day.year, day.month, day.day);
    final earliest = DateTime.now().add(const Duration(minutes: 30));
    final result = <DateTime>[];
    for (var m = open; m <= close - reservationDuration.inMinutes; m += 30) {
      final slot = base.add(Duration(minutes: m));
      if (slot.isAfter(earliest)) result.add(slot);
    }
    return result;
  }

  bool isOpenNow(Restaurant restaurant) {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    final open = restaurant.openMinutes;
    final close = restaurant.closeMinutes;
    if (close <= open) return m >= open || m < close;
    return m >= open && m < close;
  }

  Future<String?> createReservation({
    required Restaurant restaurant,
    required String tableId,
    required AppUser user,
    required DateTime start,
    required int guests,
    String comment = '',
    List<OrderItem> items = const [],
  }) async {
    final table = tableById(tableId);
    if (table == null) return 'Стол не найден';
    if (guests > table.seats) return 'За этим столом только ${table.seats} мест';
    if (start.isBefore(DateTime.now())) return 'Выберите время в будущем';
    if (!isTableFree(tableId, start)) {
      return 'Этот стол уже занят на выбранное время. Выберите другой';
    }

    final reservation = Reservation(
      id: newId(),
      restaurantId: restaurant.id,
      tableId: tableId,
      userId: user.id,
      guestName: user.name,
      phone: user.phone,
      start: start,
      guests: guests,
      status: ReservationStatus.pending,
      comment: comment,
      createdAt: DateTime.now(),
    );
    reservations.add(reservation);

    if (items.isNotEmpty) {
      orders.add(FoodOrder(
        id: newId(),
        restaurantId: restaurant.id,
        tableId: tableId,
        reservationId: reservation.id,
        createdById: user.id,
        createdByName: user.name,
        items: items,
        status: OrderStatus.fresh,
        comment: 'Предзаказ к брони',
        createdAt: DateTime.now(),
        forTime: start,
      ));
      await saveOrders();
    }
    await saveReservations();
    return null;
  }

  Future<void> confirmReservation(String id) async {
    final r = reservationById(id);
    if (r == null || r.status != ReservationStatus.pending) return;
    _replace(reservations, (Reservation x) => x.id == id,
        r.copyWith(status: ReservationStatus.confirmed));
    await saveReservations();
  }

  /// Отмена брони (гостем или рестораном). Предзаказ тоже отменяется.
  Future<void> cancelReservation(String id) async {
    final r = reservationById(id);
    if (r == null ||
        (r.status != ReservationStatus.pending &&
            r.status != ReservationStatus.confirmed)) {
      return;
    }
    _replace(reservations, (Reservation x) => x.id == id,
        r.copyWith(status: ReservationStatus.cancelled));

    final order = orderOfReservation(id);
    if (order != null && order.status.isOpen) {
      _replace(orders, (FoodOrder o) => o.id == order.id,
          order.copyWith(status: OrderStatus.cancelled));
      await saveOrders();
    }
    await saveReservations();
  }

  /// Гости пришли: бронь → «за столом», стол → «занят».
  Future<String?> seatReservation(String id) async {
    final r = reservationById(id);
    if (r == null) return 'Бронь не найдена';
    if (r.status != ReservationStatus.confirmed) {
      return 'Сначала подтвердите бронь';
    }
    final table = tableById(r.tableId);
    if (table == null) return 'Стол не найден';
    if (table.seats < r.guests) return 'За столом недостаточно мест';
    if (table.occupied) return 'Стол ещё занят. Сначала освободите его';

    _replace(reservations, (Reservation x) => x.id == id,
        r.copyWith(status: ReservationStatus.seated));
    _replace(tables, (DiningTable t) => t.id == table.id,
        table.seated(r.guests));
    await saveReservations();
    await saveTables();
    return null;
  }

  // ===================== заказы =====================

  Future<void> createOrder({
    required String restaurantId,
    required String tableId,
    required AppUser user,
    required List<OrderItem> items,
    String comment = '',
  }) async {
    orders.add(FoodOrder(
      id: newId(),
      restaurantId: restaurantId,
      tableId: tableId,
      reservationId: null,
      createdById: user.id,
      createdByName: user.name,
      items: items,
      status: OrderStatus.fresh,
      comment: comment,
      createdAt: DateTime.now(),
    ));
    await saveOrders();
  }

  /// Переводит заказ на следующий статус.
  Future<void> advanceOrder(String id) async {
    final o = orderById(id);
    if (o == null) return;
    final next = o.status.next;
    if (next == null) return;
    _replace(
      orders,
      (FoodOrder x) => x.id == id,
      o.copyWith(
        status: next,
        paidAt: next == OrderStatus.paid ? DateTime.now() : null,
      ),
    );
    await saveOrders();
  }

  Future<void> cancelOrder(String id) async {
    final o = orderById(id);
    if (o == null) return;
    _replace(orders, (FoodOrder x) => x.id == id,
        o.copyWith(status: OrderStatus.cancelled));
    await saveOrders();
  }

  /// Выручка за сегодня (оплаченные заказы).
  int revenueToday(String restaurantId) {
    final now = DateTime.now();
    return orders
        .where((o) =>
            o.restaurantId == restaurantId &&
            o.status == OrderStatus.paid &&
            o.paidAt != null &&
            o.paidAt!.year == now.year &&
            o.paidAt!.month == now.month &&
            o.paidAt!.day == now.day)
        .fold(0, (sum, o) => sum + o.total);
  }

  int paidOrdersToday(String restaurantId) {
    final now = DateTime.now();
    return orders
        .where((o) =>
            o.restaurantId == restaurantId &&
            o.status == OrderStatus.paid &&
            o.paidAt != null &&
            o.paidAt!.year == now.year &&
            o.paidAt!.month == now.month &&
            o.paidAt!.day == now.day)
        .length;
  }

  // ===================== меню =====================

  Future<void> addDish(Dish dish) async {
    dishes.add(dish);
    await saveDishes();
  }

  Future<void> updateDish(Dish dish) async {
    _replace(dishes, (Dish d) => d.id == dish.id, dish);
    await saveDishes();
  }

  Future<void> deleteDish(String id) async {
    dishes.removeWhere((d) => d.id == id);
    await saveDishes();
  }

  // ===================== отзывы =====================

  bool hasReview(String reservationId) =>
      reviews.any((r) => r.reservationId == reservationId);

  Future<String?> addReview({
    required Reservation reservation,
    required AppUser user,
    required int stars,
    required String text,
  }) async {
    if (hasReview(reservation.id)) return 'Вы уже оставили отзыв';
    reviews.add(Review(
      id: newId(),
      restaurantId: reservation.restaurantId,
      reservationId: reservation.id,
      userId: user.id,
      userName: user.name,
      stars: stars,
      text: text,
      createdAt: DateTime.now(),
    ));
    await saveReviews();
    return null;
  }

  // ===================== персонал =====================

  Future<String?> addStaff({
    required String restaurantId,
    required String name,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    if (userByPhone(phone) != null) {
      return 'Этот номер уже зарегистрирован';
    }
    final salt = makeSalt();
    users.add(AppUser(
      id: newId(),
      name: name.trim(),
      phone: normalizePhone(phone),
      role: role,
      restaurantId: restaurantId,
      salt: salt,
      passwordHash: hashPassword(password, salt),
    ));
    await saveUsers();
    return null;
  }

  Future<void> removeStaff(String userId) async {
    users.removeWhere((u) => u.id == userId);
    await saveUsers();
  }

  // ===================== профиль ресторана =====================

  Future<void> updateRestaurant(Restaurant restaurant) async {
    _replace(restaurants, (Restaurant r) => r.id == restaurant.id, restaurant);
    await saveRestaurants();
  }

  // ===================== журнал и чек-лист =====================

  Future<void> addEntry(ServiceEntry entry) async {
    entries.add(entry);
    await saveEntries();
  }

  Future<void> removeEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    await saveEntries();
  }

  Future<void> toggleEntryResolved(String id) async {
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].id == id) {
        entries[i] = entries[i].copyWith(resolved: !entries[i].resolved);
      }
    }
    await saveEntries();
  }

  Future<void> toggleChecklistItem(String id, String workerName) async {
    for (var i = 0; i < checklist.length; i++) {
      final item = checklist[i];
      if (item.id == id) {
        checklist[i] =
            item.doneToday ? item.reset() : item.markDone(workerName);
      }
    }
    await saveChecklist();
  }

  Future<void> resetChecklist(String restaurantId) async {
    for (var i = 0; i < checklist.length; i++) {
      if (checklist[i].restaurantId == restaurantId) {
        checklist[i] = checklist[i].reset();
      }
    }
    await saveChecklist();
  }

  // ===================== регистрация и вход =====================

  Future<AuthResult> registerGuest({
    required String name,
    required String phone,
    required String password,
  }) async {
    if (userByPhone(phone) != null) {
      return const AuthResult.fail(
          'Этот номер уже зарегистрирован. Войдите в аккаунт');
    }
    final salt = makeSalt();
    final user = AppUser(
      id: newId(),
      name: name.trim(),
      phone: normalizePhone(phone),
      role: UserRole.guest,
      restaurantId: null,
      salt: salt,
      passwordHash: hashPassword(password, salt),
    );
    users.add(user);
    await saveUsers();
    return AuthResult.ok(user);
  }

  /// Регистрация ресторана: создаёт ресторан, аккаунт администратора,
  /// столы и стандартный чек-лист.
  Future<AuthResult> registerRestaurant({
    required String adminName,
    required String phone,
    required String password,
    required String name,
    required String city,
    required String address,
    required String cuisine,
    required String description,
    required int openMinutes,
    required int closeMinutes,
    required int tablesCount,
    required List<String> photos,
  }) async {
    if (userByPhone(phone) != null) {
      return const AuthResult.fail(
          'Этот номер уже зарегистрирован. Войдите в аккаунт');
    }

    final restaurantId = newId();
    final salt = makeSalt();
    final admin = AppUser(
      id: newId(),
      name: adminName.trim(),
      phone: normalizePhone(phone),
      role: UserRole.admin,
      restaurantId: restaurantId,
      salt: salt,
      passwordHash: hashPassword(password, salt),
    );

    users.add(admin);
    restaurants.add(Restaurant(
      id: restaurantId,
      ownerId: admin.id,
      name: name.trim(),
      city: city,
      address: address.trim(),
      description: description.trim(),
      cuisine: cuisine,
      phone: admin.phone,
      openMinutes: openMinutes,
      closeMinutes: closeMinutes,
      photos: photos,
    ));
    for (var n = 1; n <= tablesCount; n++) {
      tables.add(DiningTable(
        id: newId(),
        restaurantId: restaurantId,
        number: n,
        seats: 4,
        zone: TableZone.hall,
      ));
    }
    checklist.addAll(ChecklistItem.defaultsFor(restaurantId));

    await saveUsers();
    await saveRestaurants();
    await saveTables();
    await saveChecklist();
    return AuthResult.ok(admin);
  }

  AuthResult login(String phone, String password) {
    final user = userByPhone(phone);
    if (user == null || hashPassword(password, user.salt) != user.passwordHash) {
      return const AuthResult.fail('Неверный номер или пароль');
    }
    return AuthResult.ok(user);
  }
}
