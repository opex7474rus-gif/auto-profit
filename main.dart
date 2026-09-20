import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main(){ WidgetsFlutterBinding.ensureInitialized(); runApp(const AutoProfitApp()); }
class AutoProfitApp extends StatelessWidget { const AutoProfitApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Auto Profit',theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.indigo),home:const HomeScreen()); }
