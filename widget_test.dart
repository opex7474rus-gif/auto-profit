import 'package:flutter_test/flutter_test.dart';
import 'package:auto_profit/main.dart';
void main(){testWidgets('opens Auto Profit', (tester) async {await tester.pumpWidget(const AutoProfitApp()); expect(find.text('Auto Profit'), findsOneWidget);});}
