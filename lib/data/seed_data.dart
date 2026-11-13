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
import '../utils/password.dart';
import 'app_repository.dart';

class _Demo {
  final String name;
  final String city;
  final String address;
  final String cuisine;
  final String description;
  final int open;
  final int close;

  const _Demo({
    required this.name,
    required this.city,
    required this.address,
    required this.cuisine,
    required this.description,
    this.open = 600,
    this.close = 1380,
  });
}

const _demos = [
  _Demo(
    name: 'Дастархан',
    city: 'Алматы',
    address: 'ул. Абая, 150',
    cuisine: 'Казахская',
    description:
        'Домашняя казахская кухня и гостеприимство. Просторный зал, уютные кабинки для семейных встреч.',
  ),
  _Demo(
    name: 'Sunset Grill',
    city: 'Алматы',
    address: 'пр. Достык, 91',
    cuisine: 'Гриль и стейки',
    description: 'Стейки на углях, барбекю и летняя терраса с видом на горы.',
    open: 720,
    close: 1440,
  ),
  _Demo(
    name: 'Bella Vita',
    city: 'Алматы',
    address: 'ул. Фурманова, 220',
    cuisine: 'Итальянская',
    description: 'Паста, пицца из дровяной печи и тирамису как в Италии.',
  ),
  _Demo(
    name: 'Nomad Kitchen',
    city: 'Астана',
    address: 'пр. Кабанбай батыра, 40',
    cuisine: 'Европейская',
    description: 'Современная европейская кухня и авторские коктейли.',
  ),
  _Demo(
    name: 'Sakura Roll',
    city: 'Астана',
    address: 'ул. Сыганак, 18',
    cuisine: 'Японская',
    description: 'Роллы, рамен и тэмпура. Свежие продукты каждый день.',
    open: 660,
  ),
  _Demo(
    name: 'Coffee Point',
    city: 'Шымкент',
    address: 'ул. Тауке хана, 12',
    cuisine: 'Кофейня',
    description: 'Свежий кофе, десерты и завтраки весь день.',
    open: 480,
    close: 1320,
  ),
  _Demo(
    name: 'Чайхана Шарк',
    city: 'Шымкент',
    address: 'ул. Байтурсынова, 77',
    cuisine: 'Восточная',
    description: 'Плов, самса, шурпа и ароматный чай на тапчанах.',
  ),
  _Demo(
    name: 'Сырдария Grill',
    city: 'Кызылорда',
    address: 'ул. Токмагамбетова, 25',
    cuisine: 'Казахская',
    description: 'Блюда из речной рыбы, шашлык и национальные супы.',
  ),
];

typedef _MenuRow = (String, int, DishCategory, String);

List<_MenuRow> _menuFor(String cuisine) {
  const s = DishCategory.starters;
  const m = DishCategory.mains;
  const d = DishCategory.drinks;
  const t = DishCategory.desserts;

  switch (cuisine) {
    case 'Казахская':
      return const [
        ('Баурсаки', 900, s, 'Горячие, со сметаной'),
        ('Казы', 3200, s, 'Нарезка домашнего казы'),
        ('Бешбармак', 4500, m, 'Мясо, лапша, лук-репка'),
        ('Манты', 2500, m, 'С мясом и тыквой, 5 штук'),
        ('Лагман', 2200, m, 'Тянутая лапша и овощи'),
        ('Шашлык из баранины', 3800, m, 'С луком и лавашом'),
        ('Чай с молоком', 600, d, 'Чайник на двоих'),
        ('Компот', 700, d, 'Домашний, из сухофруктов'),
        ('Чак-чак', 1500, t, 'С мёдом'),
      ];
    case 'Итальянская':
      return const [
        ('Брускетта', 2000, s, 'С томатами и базиликом'),
        ('Пицца Маргарита', 3500, m, 'Моцарелла, томаты, базилик'),
        ('Пицца Пепперони', 4200, m, 'Пикантная салями'),
        ('Лазанья', 4000, m, 'Мясной соус бешамель'),
        ('Паста Болоньезе', 3800, m, 'Томатно-мясной соус'),
        ('Эспрессо', 800, d, 'Двойной'),
        ('Лимонад', 1200, d, 'Домашний'),
        ('Тирамису', 2100, t, 'Классический рецепт'),
      ];
    case 'Японская':
      return const [
        ('Мисо-суп', 1500, s, 'С тофу и водорослями'),
        ('Рамен', 3300, m, 'Куриный бульон, яйцо'),
        ('Ролл Филадельфия', 4200, m, 'Лосось и сливочный сыр'),
        ('Ролл Калифорния', 3500, m, 'Краб и авокадо'),
        ('Тэмпура', 3800, m, 'Креветки в кляре'),
        ('Зелёный чай', 800, d, 'Чайник'),
        ('Лимонад', 1200, d, 'С юдзу'),
        ('Моти', 1700, t, 'Ассорти, 3 штуки'),
      ];
    case 'Гриль и стейки':
      return const [
        ('Картофель фри', 1400, s, 'С соусом'),
        ('Салат коул слоу', 1300, s, 'Капустный'),
        ('Рибай стейк', 11500, m, 'Мраморная говядина, 300 г'),
        ('Рёбра BBQ', 6900, m, 'В соусе барбекю'),
        ('Бургер на углях', 3900, m, 'Говядина, чеддер'),
        ('Морс ягодный', 900, d, 'Домашний'),
        ('Лимонад', 1200, d, 'Освежающий'),
        ('Брауни', 2000, t, 'С шариком мороженого'),
      ];
    case 'Восточная':
      return const [
        ('Самса', 1100, s, 'С бараниной, из тандыра'),
        ('Шурпа', 2600, m, 'Наваристый суп'),
        ('Плов', 3200, m, 'Узбекский, с бараниной'),
        ('Шашлык говяжий', 3500, m, 'С лавашом'),
        ('Чай чёрный', 900, d, 'Чайник'),
        ('Айран', 700, d, 'Охлаждённый'),
        ('Пахлава', 1500, t, 'С орехами'),
      ];
    case 'Кофейня':
      return const [
        ('Круассан', 1200, s, 'Масляный'),
        ('Сэндвич с курицей', 2300, m, 'На тосте'),
        ('Американо', 900, d, '250 мл'),
        ('Капучино', 1300, d, '300 мл'),
        ('Латте', 1400, d, '350 мл'),
        ('Матча латте', 1700, d, 'На растительном молоке'),
        ('Чизкейк', 1800, t, 'Нью-Йорк'),
      ];
    default:
      return const [
        ('Салат Цезарь', 2900, s, 'С курицей и пармезаном'),
        ('Крем-суп грибной', 2400, s, 'С сухариками'),
        ('Стейк из лосося', 5800, m, 'С овощами гриль'),
        ('Паста Карбонара', 3600, m, 'С беконом'),
        ('Бургер', 3200, m, 'Говядина, чеддер'),
        ('Кофе американо', 900, d, 'Крепкий'),
        ('Лимонад', 1200, d, 'Домашний'),
        ('Чизкейк', 1800, t, 'Классический'),
      ];
  }
}

/// Демо-данные для первого запуска: рестораны, меню, столы и аккаунты.
/// Пароль всех демо-аккаунтов — demo123.
void seedDemoData(AppRepository repo) {
  AppUser makeUser(
    String name,
    String phone,
    UserRole role,
    String? restaurantId,
  ) {
    final salt = makeSalt();
    return AppUser(
      id: repo.newId(),
      name: name,
      phone: phone,
      role: role,
      restaurantId: restaurantId,
      salt: salt,
      passwordHash: hashPassword(demoPassword, salt),
    );
  }

  final guest = makeUser('Демо Гость', '+77000000000', UserRole.guest, null);
  final guest2 =
      makeUser('Алмас Сериков', '+77000000020', UserRole.guest, null);
  repo.users.addAll([guest, guest2]);

  const seatsList = [2, 2, 4, 4, 4, 6, 8, 10];
  final restaurantIds = <String>[];

  for (var i = 0; i < _demos.length; i++) {
    final demo = _demos[i];
    final rid = repo.newId();
    restaurantIds.add(rid);

    final admin = makeUser(
        'Админ ${demo.name}', '+7700000000${i + 1}', UserRole.admin, rid);
    repo.users.add(admin);

    repo.restaurants.add(Restaurant(
      id: rid,
      ownerId: admin.id,
      name: demo.name,
      city: demo.city,
      address: demo.address,
      description: demo.description,
      cuisine: demo.cuisine,
      phone: admin.phone,
      openMinutes: demo.open,
      closeMinutes: demo.close,
      photos: const [],
    ));

    // Столы: зал, терраса и две кабинки.
    final restTables = <DiningTable>[];
    for (var n = 0; n < seatsList.length; n++) {
      final zone = n < 5
          ? TableZone.hall
          : (n == 5 ? TableZone.terrace : TableZone.cabin);
      restTables.add(DiningTable(
        id: repo.newId(),
        restaurantId: rid,
        number: n + 1,
        seats: seatsList[n],
        zone: zone,
      ));
    }

    // Меню.
    final restDishes = <Dish>[];
    for (final row in _menuFor(demo.cuisine)) {
      restDishes.add(Dish(
        id: repo.newId(),
        restaurantId: rid,
        name: row.$1,
        price: row.$2,
        category: row.$3,
        description: row.$4,
      ));
    }
    repo.dishes.addAll(restDishes);
    repo.checklist.addAll(ChecklistItem.defaultsFor(rid));

    if (i == 0) {
      // Сотрудники первого ресторана для проверки ролей.
      final waiter =
          makeUser('Айдос Официант', '+77000000011', UserRole.waiter, rid);
      final cook = makeUser('Мария Повар', '+77000000012', UserRole.cook, rid);
      final chef =
          makeUser('Серик Шеф', '+77000000013', UserRole.chef, rid);
      repo.users.addAll([waiter, cook, chef]);

      // Два стола заняты, чтобы сразу видеть разные статусы.
      restTables[1] = restTables[1].seated(2);
      restTables[3] = restTables[3].seated(3);

      final mains =
          restDishes.where((d) => d.category == DishCategory.mains).toList();
      final drinks =
          restDishes.where((d) => d.category == DishCategory.drinks).toList();

      OrderItem item(Dish dish, int qty) => OrderItem(
            dishId: dish.id,
            name: dish.name,
            price: dish.price,
            qty: qty,
          );

      repo.orders.add(FoodOrder(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[1].id,
        reservationId: null,
        createdById: waiter.id,
        createdByName: waiter.name,
        items: [item(mains[0], 1), item(drinks[0], 2)],
        status: OrderStatus.cooking,
        comment: '',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ));
      repo.orders.add(FoodOrder(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[3].id,
        reservationId: null,
        createdById: waiter.id,
        createdByName: waiter.name,
        items: [item(mains[1], 2), item(mains[2], 1)],
        status: OrderStatus.served,
        comment: 'Без лука',
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ));

      // Подтверждённая бронь демо-гостя на вечер с предзаказом.
      final now = DateTime.now();
      var evening = DateTime(now.year, now.month, now.day, 20);
      if (evening.isBefore(now.add(const Duration(hours: 1)))) {
        evening = evening.add(const Duration(days: 1));
      }
      final confirmed = Reservation(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[2].id,
        userId: guest.id,
        guestName: guest.name,
        phone: guest.phone,
        start: evening,
        guests: 4,
        status: ReservationStatus.confirmed,
        comment: 'День рождения, нужен торт',
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      repo.reservations.add(confirmed);
      repo.orders.add(FoodOrder(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[2].id,
        reservationId: confirmed.id,
        createdById: guest.id,
        createdByName: guest.name,
        items: [item(mains[0], 2), item(drinks[1], 4)],
        status: OrderStatus.fresh,
        comment: 'Предзаказ к брони',
        createdAt: now.subtract(const Duration(hours: 3)),
        forTime: evening,
      ));

      // Прошедший визит демо-гостя: можно попробовать оставить отзыв.
      repo.reservations.add(Reservation(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[1].id,
        userId: guest.id,
        guestName: guest.name,
        phone: guest.phone,
        start: now.subtract(const Duration(days: 3)),
        guests: 2,
        status: ReservationStatus.completed,
        comment: '',
        createdAt: now.subtract(const Duration(days: 4)),
      ));

      // Ожидающая бронь другого гостя (кабинка).
      repo.reservations.add(Reservation(
        id: repo.newId(),
        restaurantId: rid,
        tableId: restTables[6].id,
        userId: guest2.id,
        guestName: guest2.name,
        phone: guest2.phone,
        start: evening.add(const Duration(hours: 1)),
        guests: 7,
        status: ReservationStatus.pending,
        comment: '',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ));

      // Записи журнала.
      repo.entries.add(ServiceEntry(
        id: repo.newId(),
        restaurantId: rid,
        title: 'Генеральная уборка кухни',
        description: 'Обезжирили вытяжку и плиты.',
        workerName: admin.name,
        workerRole: UserRole.admin,
        category: EntryCategory.cleaning,
        date: now.subtract(const Duration(hours: 5)),
      ));
      repo.entries.add(ServiceEntry(
        id: repo.newId(),
        restaurantId: rid,
        title: 'Не работает морозильная камера №2',
        description: 'Нужно вызвать мастера.',
        workerName: chef.name,
        workerRole: UserRole.chef,
        category: EntryCategory.equipment,
        date: now.subtract(const Duration(hours: 1)),
        resolved: false,
      ));
    }

    repo.tables.addAll(restTables);
  }

  // Немного отзывов, чтобы работал рейтинг.
  const reviewTexts = [
    (5, 'Очень вкусно и быстро обслужили. Обязательно вернёмся!'),
    (4, 'Уютно, хороший сервис. Немного шумно по вечерам.'),
    (5, 'Лучшая кухня в городе, кабинка — отличная идея для семьи.'),
  ];
  for (var i = 0; i < restaurantIds.length; i++) {
    final a = reviewTexts[i % reviewTexts.length];
    final b = reviewTexts[(i + 1) % reviewTexts.length];
    repo.reviews.add(Review(
      id: repo.newId(),
      restaurantId: restaurantIds[i],
      reservationId: null,
      userId: guest2.id,
      userName: guest2.name,
      stars: a.$1,
      text: a.$2,
      createdAt: DateTime.now().subtract(Duration(days: 3 + i)),
    ));
    repo.reviews.add(Review(
      id: repo.newId(),
      restaurantId: restaurantIds[i],
      reservationId: null,
      userId: 'demo_user_$i',
      userName: 'Гость',
      stars: b.$1,
      text: b.$2,
      createdAt: DateTime.now().subtract(Duration(days: 8 + i)),
    ));
  }
}
