import 'package:flutter/material.dart';

/// Icon options for tags with their display names and icon data
class TagIcon {
  final String id;
  final String name;
  final IconData icon;

  const TagIcon({required this.id, required this.name, required this.icon});
}

/// Predefined tag icons for common use cases
class TagIcons {
  // Finance & Money
  static const TagIcon cash = TagIcon(
    id: 'cash',
    name: 'Cash',
    icon: Icons.money,
  );
  static const TagIcon creditCard = TagIcon(
    id: 'credit_card',
    name: 'Credit Card',
    icon: Icons.credit_card,
  );
  static const TagIcon bank = TagIcon(
    id: 'bank',
    name: 'Bank',
    icon: Icons.account_balance,
  );
  static const TagIcon wallet = TagIcon(
    id: 'wallet',
    name: 'Wallet',
    icon: Icons.account_balance_wallet,
  );
  static const TagIcon investment = TagIcon(
    id: 'investment',
    name: 'Investment',
    icon: Icons.trending_up,
  );

  // Food & Dining
  static const TagIcon food = TagIcon(
    id: 'food',
    name: 'Food',
    icon: Icons.restaurant,
  );

  // Transportation & Travel
  static const TagIcon car = TagIcon(
    id: 'car',
    name: 'Car',
    icon: Icons.directions_car,
  );
  static const TagIcon gas = TagIcon(
    id: 'gas',
    name: 'Gas/Fuel',
    icon: Icons.local_gas_station,
  );
  static const TagIcon flight = TagIcon(
    id: 'flight',
    name: 'Flight',
    icon: Icons.flight,
  );
  static const TagIcon train = TagIcon(
    id: 'train',
    name: 'Train',
    icon: Icons.train,
  );
  static const TagIcon bus = TagIcon(
    id: 'bus',
    name: 'Bus',
    icon: Icons.directions_bus,
  );
  static const TagIcon taxi = TagIcon(
    id: 'taxi',
    name: 'Taxi',
    icon: Icons.local_taxi,
  );
  static const TagIcon hotel = TagIcon(
    id: 'hotel',
    name: 'Hotel',
    icon: Icons.hotel,
  );

  // Shopping
  static const TagIcon shopping = TagIcon(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag,
  );
  static const TagIcon store = TagIcon(
    id: 'store',
    name: 'Store',
    icon: Icons.store,
  );
  static const TagIcon gift = TagIcon(
    id: 'gift',
    name: 'Gift',
    icon: Icons.card_giftcard,
  );

  // Entertainment & Leisure
  static const TagIcon entertainment = TagIcon(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie,
  );
  static const TagIcon music = TagIcon(
    id: 'music',
    name: 'Music',
    icon: Icons.music_note,
  );
  static const TagIcon sports = TagIcon(
    id: 'sports',
    name: 'Sports',
    icon: Icons.sports_soccer,
  );
  static const TagIcon fitness = TagIcon(
    id: 'fitness',
    name: 'Fitness',
    icon: Icons.fitness_center,
  );
  static const TagIcon game = TagIcon(
    id: 'game',
    name: 'Gaming',
    icon: Icons.sports_esports,
  );
  static const TagIcon book = TagIcon(
    id: 'book',
    name: 'Books',
    icon: Icons.book,
  );

  // Home & Utilities
  static const TagIcon home = TagIcon(
    id: 'home',
    name: 'Home',
    icon: Icons.home,
  );
  static const TagIcon utilities = TagIcon(
    id: 'utilities',
    name: 'Utilities',
    icon: Icons.build,
  );
  static const TagIcon electricity = TagIcon(
    id: 'electricity',
    name: 'Electricity',
    icon: Icons.bolt,
  );
  static const TagIcon water = TagIcon(
    id: 'water',
    name: 'Water',
    icon: Icons.water_drop,
  );
  static const TagIcon wifi = TagIcon(
    id: 'wifi',
    name: 'Internet/WiFi',
    icon: Icons.wifi,
  );
  static const TagIcon phone = TagIcon(
    id: 'phone',
    name: 'Phone',
    icon: Icons.phone,
  );
  static const TagIcon cleaning = TagIcon(
    id: 'cleaning',
    name: 'Cleaning',
    icon: Icons.cleaning_services,
  );

  // Health & Medical
  static const TagIcon health = TagIcon(
    id: 'health',
    name: 'Health',
    icon: Icons.local_hospital,
  );
  static const TagIcon pharmacy = TagIcon(
    id: 'pharmacy',
    name: 'Pharmacy',
    icon: Icons.local_pharmacy,
  );
  static const TagIcon heart = TagIcon(
    id: 'heart',
    name: 'Wellness',
    icon: Icons.favorite,
  );

  // Education & Work
  static const TagIcon education = TagIcon(
    id: 'education',
    name: 'Education',
    icon: Icons.school,
  );
  static const TagIcon work = TagIcon(
    id: 'work',
    name: 'Work',
    icon: Icons.work,
  );
  static const TagIcon laptop = TagIcon(
    id: 'laptop',
    name: 'Laptop/Computer',
    icon: Icons.laptop,
  );
  static const TagIcon briefcase = TagIcon(
    id: 'briefcase',
    name: 'Business',
    icon: Icons.business_center,
  );

  // Personal & Lifestyle
  static const TagIcon person = TagIcon(
    id: 'person',
    name: 'Personal',
    icon: Icons.person,
  );
  static const TagIcon family = TagIcon(
    id: 'family',
    name: 'Family',
    icon: Icons.family_restroom,
  );
  static const TagIcon pet = TagIcon(id: 'pet', name: 'Pet', icon: Icons.pets);
  static const TagIcon beauty = TagIcon(
    id: 'beauty',
    name: 'Beauty',
    icon: Icons.face,
  );
  static const TagIcon clothing = TagIcon(
    id: 'clothing',
    name: 'Clothing',
    icon: Icons.checkroom,
  );

  // General & Organization
  static const TagIcon star = TagIcon(
    id: 'star',
    name: 'Star/Favorite',
    icon: Icons.star,
  );
  static const TagIcon flag = TagIcon(
    id: 'flag',
    name: 'Flag',
    icon: Icons.flag,
  );
  static const TagIcon label = TagIcon(
    id: 'label',
    name: 'Label',
    icon: Icons.label,
  );
  static const TagIcon calendar = TagIcon(
    id: 'calendar',
    name: 'Calendar',
    icon: Icons.calendar_today,
  );
  static const TagIcon timer = TagIcon(
    id: 'timer',
    name: 'Timer',
    icon: Icons.timer,
  );
  static const TagIcon important = TagIcon(
    id: 'important',
    name: 'Important',
    icon: Icons.priority_high,
  );
  static const TagIcon notification = TagIcon(
    id: 'notification',
    name: 'Notification',
    icon: Icons.notifications,
  );

  // Miscellaneous
  static const TagIcon camera = TagIcon(
    id: 'camera',
    name: 'Camera/Photo',
    icon: Icons.camera_alt,
  );
  static const TagIcon explore = TagIcon(
    id: 'explore',
    name: 'Explore',
    icon: Icons.explore,
  );
  static const TagIcon location = TagIcon(
    id: 'location',
    name: 'Location',
    icon: Icons.location_on,
  );
  static const TagIcon chart = TagIcon(
    id: 'chart',
    name: 'Analytics',
    icon: Icons.bar_chart,
  );

  /// Get all available tag icons
  static List<TagIcon> get allIcons => [
    // Finance & Money
    cash,
    creditCard,
    bank,
    wallet,
    investment,
    // Food & Dining
    food,
    // Transportation & Travel
    car,
    gas,
    flight,
    train,
    bus,
    taxi,
    hotel,
    // Shopping
    shopping,
    store,
    gift,
    // Entertainment & Leisure
    entertainment,
    music,
    sports,
    fitness,
    game,
    book,
    // Home & Utilities
    home,
    utilities,
    electricity,
    water,
    wifi,
    phone,
    cleaning,
    // Health & Medical
    health,
    pharmacy,
    heart,
    // Education & Work
    education,
    work,
    laptop,
    briefcase,
    // Personal & Lifestyle
    person,
    family,
    pet,
    beauty,
    clothing,
    // General & Organization
    star,
    flag,
    label,
    calendar,
    timer,
    important,
    notification,
    // Miscellaneous
    camera,
    explore,
    location,
    chart,
  ];

  /// Get icon by ID
  static TagIcon? getIconById(String? id) {
    if (id == null) return null;
    try {
      return allIcons.firstWhere((icon) => icon.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Default icon when none is selected
  static const TagIcon defaultIcon = label;
}
