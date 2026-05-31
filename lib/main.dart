import 'dart:io'; 
import 'dart:convert' as dart_convert; 
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_avif/flutter_avif.dart';

// --- 五花馬智能點餐系統 v19.5 氣溫不換行置中版 ---
void main() => runApp(const WuhuamaApp());

class WuhuamaApp extends StatelessWidget {
  const WuhuamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '五花馬智能點餐系統',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
        fontFamily: 'sans-serif',
        cardTheme: const CardThemeData(
          elevation: 5,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
      ),
      home: const OrderScreen(),
    );
  }
}

class Dish {
  final String name;
  final String imagePath;
  final bool isBeef, isSoup, isNoodle, isVeg, isDumpling;
  final String category;
  final int price;
  final String portion;
  int stock; 

  Dish({
    required this.name,
    required this.imagePath,
    required this.category,
    this.isBeef = false,
    this.isSoup = false,
    this.isNoodle = false,
    this.isVeg = false,
    this.isDumpling = false,
    this.price = 70,
    this.stock = 50, 
    this.portion = '',
  });
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _hasProcessed = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "點擊下方麥克風，告訴我想吃什麼...";
  
  double? _currentTemp = 28.0; 
  bool _isLoadingWeather = false;

  List<Dish> _recommendedList = []; 
  final Map<Dish, int> _cart = {}; 

  final List<Dish> _menu = [
    Dish(name: "高麗菜水餃", imagePath: "assets/p1.avif", isDumpling: true, category: 'p', price: 70, portion: "10顆"),
    Dish(name: "韭菜水餃", imagePath: "assets/p2.avif", isDumpling: true, category: 'p', price: 70, portion: "10顆"),
    Dish(name: "地瓜葉水餃", imagePath: "assets/p3.avif", isDumpling: true, category: 'p', price: 75, portion: "10顆"),
    Dish(name: "玉米水餃", imagePath: "assets/p4.avif", isDumpling: true, category: 'p', price: 75, portion: "10顆"),
    Dish(name: "南瓜水餃", imagePath: "assets/p5.avif", isDumpling: true, category: 'p', price: 80, portion: "10顆"),
    Dish(name: "虱目魚水餃", imagePath: "assets/p6.avif", isDumpling: true, category: 'p', price: 90, portion: "10顆"),
    Dish(name: "蝦仁水餃", imagePath: "assets/p7.avif", isDumpling: true, category: 'p', price: 95, portion: "10顆"),
    Dish(name: "酸辣湯餃", imagePath: "assets/p8.avif", isDumpling: true, isSoup: true, category: 'p', price: 95, portion: "8顆"),
    Dish(name: "牛肉湯餃", imagePath: "assets/p9.avif", isDumpling: true, isSoup: true, isBeef: true, category: 'p', price: 125, portion: "8顆"),
    Dish(name: "黃金地瓜餡餅", imagePath: "assets/f1.avif", category: 'f', price: 45, portion: "1份"),
    Dish(name: "鍋貼", imagePath: "assets/f2.avif", category: 'f', price: 65, portion: "8顆"),
    Dish(name: "韭菜盒子", imagePath: "assets/f3.avif", category: 'f', price: 50, portion: "1個"),
    Dish(name: "蔥油餅", imagePath: "assets/f4.avif", category: 'f', price: 55, portion: "1份"),
    Dish(name: "港式蘿蔔糕", imagePath: "assets/f5.avif", category: 'f', price: 60, portion: "3塊"),
    Dish(name: "蔥花蛋捲餅", imagePath: "assets/f6.avif", category: 'f', price: 65, portion: "1份"),
    Dish(name: "豬肉餡餅", imagePath: "assets/f7.avif", category: 'f', price: 50, portion: "1個"),
    Dish(name: "牛肉捲餅", imagePath: "assets/f8.avif", isBeef: true, category: 'f', price: 125, portion: "1份"),
    Dish(name: "港式鳳爪", imagePath: "assets/f9.avif", category: 'f', price: 85, portion: "1份"),
    Dish(name: "蟹黃燒賣", imagePath: "assets/f10.avif", category: 'f', price: 95, portion: "6顆"),
    Dish(name: "蝦仁燒賣", imagePath: "assets/f11.avif", category: 'f', price: 105, portion: "6顆"),
    Dish(name: "小籠湯包", imagePath: "assets/f12.avif", isSoup: true, category: 'f', price: 110, portion: "8顆"),
    Dish(name: "韭黃鮮肉煎餃", imagePath: "assets/f13.avif", category: 'f', price: 85, portion: "8顆"),
    Dish(name: "翡翠雞蛋蒸餃", imagePath: "assets/f14.avif", category: 'f', price: 85, portion: "8顆"),
    Dish(name: "招牌乾麵", imagePath: "assets/q1.avif", isNoodle: true, category: 'q', price: 65, portion: "1碗"),
    Dish(name: "招牌湯麵", imagePath: "assets/q2.avif", isNoodle: true, isSoup: true, category: 'q', price: 75, portion: "1碗"),
    Dish(name: "榨菜肉絲麵", imagePath: "assets/q3.avif", isNoodle: true, isSoup: true, category: 'q', price: 85, portion: "1碗"),
    Dish(name: "黑芝麻麻醬麵", imagePath: "assets/q4.avif", isNoodle: true, isVeg: true, category: 'q', price: 75, portion: "1碗"),
    Dish(name: "川味擔擔麵", imagePath: "assets/q5.avif", isNoodle: true, category: 'q', price: 80, portion: "1碗"),
    Dish(name: "牛肉麵", imagePath: "assets/q6.avif", isNoodle: true, isBeef: true, isSoup: true, category: 'q', price: 175, portion: "1碗"),
    Dish(name: "酸辣湯", imagePath: "assets/w1.avif", isSoup: true, category: 'w', price: 45, portion: "1碗"),
    Dish(name: "香菇貢丸湯", imagePath: "assets/w2.avif", isSoup: true, category: 'w', price: 45, portion: "1碗"),
    Dish(name: "溫州大雲吞湯", imagePath: "assets/w3.avif", isSoup: true, category: 'w', price: 85, portion: "1碗"),
    Dish(name: "藥膳排骨湯", imagePath: "assets/w4.avif", isSoup: true, category: 'w', price: 110, portion: "1碗"),
    Dish(name: "元盎四神豬肚湯", imagePath: "assets/w5.avif", isSoup: true, category: 'w', price: 110, portion: "1碗"), // 註：此處維持原程式碼欄位
    Dish(name: "叉燒炒飯", imagePath: "assets/r1.avif", category: 'r', price: 110, portion: "1盤"),
    Dish(name: "揚州炒飯", imagePath: "assets/r2.avif", category: 'r', price: 120, portion: "1盤"),
  ];

  int chineseToNumber(String text) {
    Map<String, int> numbers = {
      '零': 0, '一': 1, '二': 2, '兩': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    };
    if (text == '十') return 10;
    if (text.contains('十')) {
      List<String> parts = text.split('十');
      int tens = 1; int units = 0;
      if (parts[0].isNotEmpty) tens = numbers[parts[0]] ?? 1;
      if (parts.length > 1 && parts[1].isNotEmpty) units = numbers[parts[1]] ?? 0;
      return tens * 10 + units;
    }
    if (text.contains('百')) {
      List<String> parts = text.split('百');
      int hundreds = numbers[parts[0]] ?? 1;
      return hundreds * 100;
    }
    return numbers[text] ?? 1;
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  int get _totalPrice => _cart.entries.fold(0, (sum, e) => sum + (e.key.price * e.value));
  int get _totalCount => _cart.values.fold(0, (sum, count) => sum + count);

  void _removeFromCart(Dish dish, [int quantity = 1]) {
    if (!_cart.containsKey(dish)) return;
    setState(() {
      if (_cart[dish]! <= quantity) {
        dish.stock += _cart[dish]!;
        _cart.remove(dish);
      } else {
        _cart[dish] = _cart[dish]! - quantity;
        dish.stock += quantity;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已取消 $quantity 份 ${dish.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _addToCart(Dish dish) {
    if (dish.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dish.name} 已售完'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() {
      _cart[dish] = (_cart[dish] ?? 0) + 1;
      dish.stock--;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已點購 ${dish.name}，剩餘 ${dish.stock} 份'),
        duration: const Duration(milliseconds: 700),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _analyzeInput(String input) {
    if (input.isEmpty) return;

    bool isCancelIntent = input.contains('取消') || input.contains('不要') || input.contains('刪除') || input.contains('移除');
    bool isOrderIntent = input.contains('我要') || input.contains('點') || input.contains('想要') || input.contains('幫我') || input.contains('要') || input.contains('想要') || input.contains('吃');

    if (isCancelIntent) {
      bool hasRemovedAny = false;
      for (var dish in _menu) {
        if (input.contains(dish.name)) {
          int quantity = 1; 

          RegExp reg = RegExp(r'(\d+|[零一二兩三四五六七八九十百]+)');
          Match? match = reg.firstMatch(input);
          if (match != null) {
            String quantityText = match.group(1)!;
            if (RegExp(r'\d+').hasMatch(quantityText)) {
              quantity = int.parse(quantityText);
            } else {
              quantity = chineseToNumber(quantityText);
            }
          }

          _removeFromCart(dish, quantity);
          hasRemovedAny = true;
        }
      }

      if (hasRemovedAny) {
        setState(() { _text = "已為您處理取消指令：$input"; });
      } else {
        setState(() { _text = "你想取消什麼呢？請說「取消高麗菜水餃」"; });
      }
      return; 
    }

    bool hasDishName = _menu.any((dish) => input.contains(dish.name));
    if (hasDishName && !isOrderIntent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有聽到餐點，但請說「我要 / 幫我 / 來一份」或「取消」會更準確'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() { _text = "請重新說明，例如：我要酸辣湯 或 取消酸辣湯"; });
      return;
    }

    for (var dish in _menu) {
      RegExp reg = RegExp(r'(\d+|[零一二兩三四五六七八九十百]+)\s*(份|碗|個|盤|塊|顆)?\s*' + dish.name);
      Match? match = reg.firstMatch(input);

      if (match != null) {
        String quantityText = match.group(1)!;
        int quantity = 1;

        if (RegExp(r'\d+').hasMatch(quantityText)) {
          quantity = int.parse(quantityText);
        } else {
          quantity = chineseToNumber(quantityText);
        }

        if (quantity > dish.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dish.name} 庫存不足，目前只剩 ${dish.stock} 份'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          quantity = dish.stock;
        }

        for (int i = 0; i < quantity; i++) {
          _addToCart(dish);
        }
      } else if (input.contains(dish.name) && !input.contains(RegExp(r'(\d+|[零一二兩三四五六七八九十百]+)'))) {
        _addToCart(dish); 
      }
    }

    List<Dish> dumplings = _menu.where((d) => d.isDumpling || d.name.contains('水餃')).toList();
    List<Dish> friedRice = _menu.where((d) => d.category == 'r' || d.name.contains('炒飯')).toList();
    List<Dish> soups = _menu.where((d) => d.isSoup || d.name.contains('湯')).toList();
    List<Dish> noodles = _menu.where((d) => d.isNoodle || d.name.contains('麵')).toList();
    List<Dish> pancakes = _menu.where((d) => d.category == 'f' || d.name.contains('餅')).toList();

    List<List<Dish>> activeCategories = [];
    if (input.contains('水餃')) activeCategories.add(dumplings);
    if (input.contains('炒飯')) activeCategories.add(friedRice);
    if (input.contains('湯')) activeCategories.add(soups);
    if (input.contains('麵')) activeCategories.add(noodles);
    if (input.contains('餅')) activeCategories.add(pancakes);

    List<Dish> finalDisplay = [];
    if (activeCategories.isNotEmpty) {
      int countPerCategory = (8 / activeCategories.length).floor();
      for (var categoryList in activeCategories) {
        finalDisplay.addAll(categoryList.take(countPerCategory));
      }
      if (finalDisplay.length < 8) {
        int deficit = 8 - finalDisplay.length;
        finalDisplay.addAll(activeCategories[0].where((d) => !finalDisplay.contains(d)).take(deficit));
      }
    } else {
      finalDisplay = _menu.where((d) => 
          input.contains(d.name) || (d.name.length >= 2 && input.contains(d.name.substring(0, 2)))
      ).toList();
    }

    setState(() {
      _recommendedList = finalDisplay.take(8).toList();
      if (_recommendedList.isEmpty && input.length > 1) {
        _text = "找不到與「$input」相關的餐點，建議說「我想吃水餃跟炒飯」！";
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      _hasProcessed = false;
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              if (val.finalResult && !_hasProcessed) {
                _hasProcessed = true;
                _analyzeInput(_text);
                _isListening = false;
                _speech.stop();
              }
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handleCheckout() {
    if (_cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("您的訂單內容", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              ..._cart.entries.map((e) => ListTile(
                title: Text(e.key.name),
                trailing: Text("x ${e.value} (\$${e.key.price * e.value})"),
              )),
              const Divider(thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("應付金額：", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$$_totalPrice", style: const TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("繼續點餐")),
          FilledButton(
            onPressed: () {
              setState(() { _cart.clear(); _recommendedList = []; _text = "點擊下方麥克風，告訴我想吃什麼..."; });
              Navigator.pop(context);
            },
            child: const Text("確認送出"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        
        // 🎵 關鍵改動：leadingWidth 加大到 160，並使用 maxLines: 1 + 停用折行，確保絕對維持在同一行
        leadingWidth: 160,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '台南目前氣溫 $_currentTemp°C',
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w600, 
                color: Colors.black87
              ),
            ),
          ),
        ),

        title: const Text(
          '五花馬智能點餐系統', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                for (var entry in _cart.entries) {
                  entry.key.stock += entry.value;
                }
                _cart.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('訂單已重設'), backgroundColor: Colors.orange),
              );
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.red, size: 28)
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.red,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          elevation: 6,
          backgroundColor: Colors.red,
          onPressed: _listen,
          child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("共點購 $_totalCount 份餐點", style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    Text("\$$_totalPrice", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _handleCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red, 
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: const Text("前往結帳", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Text(
              _text, 
              style: const TextStyle(fontSize: 22, color: Colors.black87, fontWeight: FontWeight.w600), 
              textAlign: TextAlign.center
            ),
          ),
          Expanded(
            child: _recommendedList.isEmpty
                ? const Center(child: Text("今天想吃點什麼？\n可以試著說說關鍵字喔！\n或是對我說「取消高麗菜水餃」", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      childAspectRatio: 0.8, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _recommendedList.length,
                    itemBuilder: (context, index) {
                      final dish = _recommendedList[index];
                      final count = _cart[dish] ?? 0;
                      return GestureDetector(
                        onTap: () => _addToCart(dish),
                        child: Badge(
                          label: Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          isLabelVisible: count > 0,
                          backgroundColor: Colors.red,
                          largeSize: 26,
                          child: Card(
                            elevation: 5,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    child: AvifImage.asset(
                                      dish.imagePath, 
                                      fit: BoxFit.cover, 
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Column(
                                    children: [
                                      Text(
                                        dish.name, 
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "\$${dish.price}", 
                                        style: const TextStyle(fontSize: 17, color: Colors.red, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dish.portion,
                                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "剩餘 ${dish.stock} 份",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: dish.stock <= 10 ? Colors.red : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}