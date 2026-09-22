import 'car.dart';
import 'constants.dart';
import 'utils.dart';

class MonthStat {
  final String label;
  final double profit;
  final int count;
  MonthStat({
    required this.label,
    required this.profit,
    required this.count,
  });
}

class CategoryStat {
  final String name;
  final double amount;
  CategoryStat({required this.name, required this.amount});
}

class BrandStat {
  final String name;
  final int count;
  final double totalProfit;
  final double avgProfit;
  final double avgDays;
  BrandStat({
    required this.name,
    required this.count,
    required this.totalProfit,
    required this.avgProfit,
    required this.avgDays,
  });
}

class Analytics {
  final List<Car> cars;

  Analytics(this.cars);

  List<Car> get soldCars => cars.where((c) => c.isSold).toList();
  List<Car> get stockCars => cars.where((c) => !c.isSold).toList();
  List<Car> get staleCars => cars.where((c) => c.isStale).toList();

  List<Car> get soldThisMonth => soldCars.where((c) {
        final d = c.saleDateTime;
        if (d == null) return false;
        return isSameMonth(d, DateTime.now());
      }).toList();

  int get soldThisMonthCount => soldThisMonth.length;
  int get soldAllTimeCount => soldCars.length;

  double get profitThisMonth =>
      soldThisMonth.fold(0.0, (s, c) => s + c.profit);

  double get averageProfitThisMonth => soldThisMonthCount == 0
      ? 0
      : profitThisMonth / soldThisMonthCount;

  double get totalPurchase => cars.fold(0, (s, c) => s + c.purchase);
  double get totalExpenses =>
      cars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvested => totalPurchase + totalExpenses;

  double get totalPurchaseStock =>
      stockCars.fold(0, (s, c) => s + c.purchase);
  double get totalExpensesStock =>
      stockCars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvestedStock =>
      totalPurchaseStock + totalExpensesStock;

  double get totalPurchaseSold =>
      soldCars.fold(0, (s, c) => s + c.purchase);
  double get totalExpensesSold =>
      soldCars.fold(0, (s, c) => s + c.expensesTotal);
  double get totalInvestedSold =>
      totalPurchaseSold + totalExpensesSold;

  double get totalRevenue => soldCars.fold(0, (s, c) => s + c.sale);
  double get totalProfit => soldCars.fold(0, (s, c) => s + c.profit);

  double get averageProfit =>
      soldCars.isEmpty ? 0 : totalProfit / soldCars.length;

  double get averagePurchase =>
      cars.isEmpty ? 0 : totalPurchase / cars.length;

  double get averageSalePrice =>
      soldCars.isEmpty ? 0 : totalRevenue / soldCars.length;

  double get averageDaysToSell => soldCars.isEmpty
      ? 0
      : soldCars.map((c) => c.daysInStock).reduce((a, b) => a + b) /
          soldCars.length;

  double get averageInvestment =>
      cars.isEmpty ? 0 : totalInvested / cars.length;

  double get profitability => totalInvestedSold == 0
      ? 0
      : (totalProfit / totalInvestedSold) * 100;

  List<Car> get partnerCars =>
      cars.where((c) => c.partnerAmount > 0).toList();
  List<Car> get partnerStock =>
      stockCars.where((c) => c.partnerAmount > 0).toList();
  List<Car> get partnerSold =>
      soldCars.where((c) => c.partnerAmount > 0).toList();

  int get partnerCarsCount => partnerCars.length;
  int get partnerCarsCountStock => partnerStock.length;
  int get partnerCarsCountSold => partnerSold.length;

  double get totalPartnerInvestment =>
      partnerCars.fold(0.0, (s, c) => s + c.partnerAmount);
  double get totalPartnerStock =>
      partnerStock.fold(0.0, (s, c) => s + c.partnerAmount);
  double get totalPartnerSold =>
      partnerSold.fold(0.0, (s, c) => s + c.partnerAmount);

  double get partnerProfitShare =>
      partnerSold.fold(0.0, (s, c) => s + c.partnerProfit);

  double get myProfitShare => totalProfit - partnerProfitShare;

  double get potentialProfit {
    if (soldCars.isEmpty) return 0;
    final totalInvestedSoldLocal =
        soldCars.fold(0.0, (s, c) => s + c.invested);
    if (totalInvestedSoldLocal == 0) return 0;
    final margin = totalProfit / totalInvestedSoldLocal;
    return totalInvestedStock * margin;
  }

  List<BrandStat> get brandStats {
    final map = <String, List<Car>>{};
    for (final c in soldCars) {
      final brand = c.make.trim().isEmpty ? 'Без марки' : c.make.trim();
      map.putIfAbsent(brand, () => []).add(c);
    }
    final list = map.entries.map((e) {
      final listCars = e.value;
      final total = listCars.fold(0.0, (s, c) => s + c.profit);
      final avg = listCars.isEmpty ? 0.0 : total / listCars.length;
      final avgD = listCars.isEmpty
          ? 0.0
          : listCars.map((c) => c.daysInStock).reduce((a, b) => a + b) /
              listCars.length;
      return BrandStat(
        name: e.key,
        count: listCars.length,
        totalProfit: total,
        avgProfit: avg,
        avgDays: avgD,
      );
    }).toList();
    list.sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
    return list;
  }

  Car? get bestCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit >= b.profit ? a : b);
  }

  Car? get worstCar {
    if (soldCars.isEmpty) return null;
    return soldCars.reduce((a, b) => a.profit <= b.profit ? a : b);
  }

  Map<String, int> get statusCounts {
    final map = <String, int>{};
    for (final s in kStatuses) {
      map[s] = cars.where((c) => c.status == s).length;
    }
    return map;
  }

  List<CategoryStat> get topExpenseCategories {
    final map = <String, double>{};
    for (final c in cars) {
      for (final e in c.expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => CategoryStat(name: e.key, amount: e.value))
        .toList();
  }

  List<MonthStat> get monthlyStats {
    final now = DateTime.now();
    final months = <MonthStat>[];
    for (int i = 5; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      final soldInMonth = soldCars.where((c) {
        final d = c.saleDateTime;
        if (d == null) return false;
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();
      final profit = soldInMonth.fold(0.0, (s, c) => s + c.profit);
      months.add(MonthStat(
        label: '${start.month.toString().padLeft(2, '0')}/'
            '${(start.year % 100).toString().padLeft(2, '0')}',
        profit: profit,
        count: soldInMonth.length,
      ));
    }
    return months;
  }
}
