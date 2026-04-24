import 'package:flutter/material.dart';

void main() {
  runApp(const ElsasJourneyApp());
}

class ElsasJourneyApp extends StatelessWidget {
  const ElsasJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elsa\'s Magical Journey',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A306D),
        scaffoldBackgroundColor: const Color(0xFFF3E5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double currentWeight = 76.0;
  List<Map<String, dynamic>> todaysMeals = [];

  // The Timekeeper! 🕰️
  DateTime currentActiveDay = DateTime.now();

  int get caloriesLoggedToday {
    int total = 0;
    for (var meal in todaysMeals) {
      total += (meal['calories'] as int);
    }
    return total;
  }

  int calculateDailyGoal() {
    double estimatedBMR = 1760.0 - ((76.0 - currentWeight) * 12.0);
    double tdee = estimatedBMR * 1.2;
    double dynamicGoal = tdee - 550.0;
    return dynamicGoal.toInt();
  }

  // Rolling 7-day window! 📊
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Mon', 'intake': 1500},
    {'day': 'Tue', 'intake': 1600},
    {'day': 'Wed', 'intake': 1450},
    {'day': 'Thu', 'intake': 1550},
    {'day': 'Fri', 'intake': 1400},
    {'day': 'Sat', 'intake': 1700},
    {'day': 'Today', 'intake': 0},
  ];

  // The Midnight Magic Spell 🌙✨
  void _checkMidnightReset() {
    DateTime now = DateTime.now();
    // If the day of the month has changed...
    if (now.day != currentActiveDay.day) {
      setState(() {
        // 1. Rename the old "Today" to its actual day name (e.g., "Sun")
        String yesterdayName = [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][currentActiveDay.weekday - 1];
        weeklyData.last['day'] = yesterdayName;
        weeklyData.last['intake'] = caloriesLoggedToday;

        // 2. Shift everything left (remove the oldest day)
        weeklyData.removeAt(0);

        // 3. Add a brand new "Today" at the end!
        weeklyData.add({'day': 'Today', 'intake': 0});

        // 4. Wipe the spellbook clean for the new day
        todaysMeals.clear();
        currentActiveDay = now;
      });
    }
  }

  void _updateWeightDialog() {
    TextEditingController weightController = TextEditingController(
      text: currentWeight.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Update Weight 🦇',
          style: TextStyle(color: Color(0xFFE1BEE7)),
        ),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Weight (kg)',
            labelStyle: TextStyle(color: Color(0xFF7B1FA2)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7B1FA2)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                currentWeight =
                    double.tryParse(weightController.text) ?? currentWeight;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Save Magic 🪄',
              style: TextStyle(color: Color(0xFFCE93D8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if Cinderella's carriage needs to reset every time the screen updates!
    _checkMidnightReset();

    int todaysGoal = calculateDailyGoal();
    int remainingCalories = todaysGoal - caloriesLoggedToday;

    // Dynamically update today's intake on the graph
    weeklyData.last['intake'] = caloriesLoggedToday;

    double maxIntake = 2000.0;
    double goalHeightFactor = todaysGoal / maxIntake;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✨ Elsa\'s Journey ✨',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // The Reset button is GONE! 🦇
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Magic Energy Card 🖤✨
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFF4A306D), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Daily Allowance 🦇',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A306D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$remainingCalories kcal',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'of $todaysGoal kcal total',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // The Animated Kuromi Bar Graph 📊✨
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Weekly Energy 💜',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A306D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 100 * goalHeightFactor + 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0
                                        ? const Color(
                                            0xFF2C2C2C,
                                          ).withOpacity(0.4)
                                        : Colors.transparent,
                                    height: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: weeklyData.map((data) {
                              double rawHeight = data['intake'] / maxIntake;
                              double heightFactor = rawHeight > 1.0
                                  ? 1.0
                                  : rawHeight;
                              bool metGoal = data['intake'] <= todaysGoal;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    width: 20,
                                    height: 100 * heightFactor,
                                    decoration: BoxDecoration(
                                      color: metGoal
                                          ? const Color(0xFF7B1FA2)
                                          : Colors.grey[400],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['day'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: data['day'] == 'Today'
                                          ? const Color(0xFF7B1FA2)
                                          : Colors.black54,
                                      fontWeight: data['day'] == 'Today'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Timeline & Dynamic Weight Goals 🦋
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4A306D),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Timeline 🗓️',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '174',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Days Left',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _updateWeightDialog,
                    child: Card(
                      color: const Color(0xFF2C2C2C),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current 🦋',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$currentWeight',
                              style: const TextStyle(
                                fontSize: 28,
                                color: Color(0xFFE1BEE7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'kg (Tap to edit)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily Spellbook 📓🦇
            const Text(
              '  Today\'s Spellbook 📓',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A306D),
              ),
            ),
            const SizedBox(height: 10),
            todaysMeals.isEmpty
                ? Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No magic consumed yet today! 🌸',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysMeals.length,
                    itemBuilder: (context, index) {
                      final meal = todaysMeals[index];
                      return Card(
                        color: const Color(0xFF2C2C2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFE1BEE7),
                          ),
                          title: Text(
                            meal['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '${meal['calories']} kcal',
                            style: const TextStyle(
                              color: Color(0xFFCE93D8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LogMealScreen()),
          );

          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              todaysMeals.add(result);
            });
            // Also check for reset right after logging just in case!
            _checkMidnightReset();
          }
        },
        backgroundColor: const Color(0xFF4A306D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Log Meal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✨ Log a Meal ✨',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What did you eat, gorgeous? 🦇💜',
              style: TextStyle(
                fontSize: 22,
                color: Color(0xFF4A306D),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _mealNameController,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                labelStyle: const TextStyle(color: Color(0xFF4A306D)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.restaurant,
                  color: Color(0xFF4A306D),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calories',
                labelStyle: const TextStyle(color: Color(0xFF4A306D)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                String name = _mealNameController.text.isEmpty
                    ? 'Mystery Snack'
                    : _mealNameController.text;
                int calories = int.tryParse(_caloriesController.text) ?? 0;
                Navigator.pop(context, {'name': name, 'calories': calories});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A306D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Add to Daily Pool 🪄',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
