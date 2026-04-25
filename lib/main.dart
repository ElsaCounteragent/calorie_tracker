import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  double currentWeight = 75.5;
  double targetWeight = 63.6;

  // The Timekeeper! 🕰️
  DateTime currentActiveDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMemory(); // 🪄 Wakes up your saved data!
  }

  // 🔮 Reads the memory when the app opens
  Future<void> _loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentWeight = prefs.getDouble('weight') ?? 76.0;
      targetWeight = prefs.getDouble('targetWeight') ?? 63.6;
      String? activeDayStr = prefs.getString('activeDay');
      if (activeDayStr != null) currentActiveDay = DateTime.parse(activeDayStr);

      String? weekJson = prefs.getString('weeklyData');
      if (weekJson != null) {
        List<dynamic> decoded = jsonDecode(weekJson);
        weeklyData.clear();
        for (var day in decoded) {
          weeklyData.add({
            'day': day['day'],
            'intake': day['intake'],
            // Safety check in case it's an old save without meals!
            'meals': day['meals'] != null
                ? List<Map<String, dynamic>>.from(day['meals'])
                : [],
          });
        }
      }
    });
  }

  // 💾 Writes the memory to the phone
  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight', currentWeight);
    await prefs.setDouble('targetWeight', targetWeight);
    await prefs.setString('activeDay', currentActiveDay.toIso8601String());
    await prefs.setString('weeklyData', jsonEncode(weeklyData));
  }

  int calculateDailyGoal() {
    double estimatedBMR = 1760.0 - ((76.0 - currentWeight) * 12.0);
    double tdee = estimatedBMR * 1.2;
    double dynamicGoal = tdee - 550.0;
    return dynamicGoal.toInt();
  }

  int calculateDaysLeft() {
    // If you already reached your goal, the countdown is 0! 🎉
    if (currentWeight <= targetWeight) return 0;

    // 1 kg of weight is roughly 7700 kcal.
    // Your daily deficit is strictly set to 550 kcal in your formula.
    double dailyDeficit = 550.0;
    double kgLostPerDay = dailyDeficit / 7700.0;

    double kgToLose = currentWeight - targetWeight;
    double daysLeft = kgToLose / kgLostPerDay;

    return daysLeft.ceil(); // Rounds up to the nearest whole day!
  }

  int selectedDayIndex =
      6; // 6 means the graph is looking at "Today" by default!
  // Rolling 7-day window! 📊
  // REPLACE your old weeklyData list with this one! 📊✨
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Day 1', 'intake': 0, 'meals': []},
    {'day': 'Day 2', 'intake': 0, 'meals': []},
    {'day': 'Day 3', 'intake': 0, 'meals': []},
    {'day': 'Day 4', 'intake': 0, 'meals': []},
    {'day': 'Day 5', 'intake': 0, 'meals': []},
    {'day': 'Yesterday', 'intake': 0, 'meals': []},
    {'day': 'Today', 'intake': 0, 'meals': []},
  ];

  // The Midnight Magic Spell 🌙✨
  void _checkMidnightReset() {
    DateTime now = DateTime.now();
    if (now.day != currentActiveDay.day) {
      setState(() {
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

        weeklyData.removeAt(0);
        // Add a totally blank day with an empty spellbook!
        weeklyData.add({'day': 'Today', 'intake': 0, 'meals': []});

        currentActiveDay = now;
        selectedDayIndex = 6; // Snap back to Today
      });
      _saveMemory();
    }
  }

  void _updateWeightDialog() {
    TextEditingController weightController = TextEditingController(
      text: currentWeight.toString(),
    );
    TextEditingController targetController = TextEditingController(
      text: targetWeight.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Update Magic 🦇',
          style: TextStyle(color: Color(0xFFE1BEE7)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Weight (kg)',
                labelStyle: TextStyle(color: Color(0xFF7B1FA2)),
              ),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Dream Goal (kg)',
                labelStyle: TextStyle(color: Color(0xFF7B1FA2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                currentWeight =
                    double.tryParse(weightController.text) ?? currentWeight;
                targetWeight =
                    double.tryParse(targetController.text) ?? targetWeight;
              });
              _saveMemory();
              Navigator.pop(context);
            },
            child: const Text(
              'Save 🪄',
              style: TextStyle(color: Color(0xFFCE93D8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(int mealIndex) {
    TextEditingController nameController = TextEditingController(
      text: weeklyData[selectedDayIndex]['meals'][mealIndex]['name'],
    );
    TextEditingController calController = TextEditingController(
      text: weeklyData[selectedDayIndex]['meals'][mealIndex]['calories']
          .toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Edit Magic 🦇',
          style: TextStyle(color: Color(0xFFE1BEE7)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                labelStyle: TextStyle(color: Color(0xFF7B1FA2)),
              ),
            ),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Calories',
                labelStyle: TextStyle(color: Color(0xFF7B1FA2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // DELETE BUTTON
              setState(() {
                weeklyData[selectedDayIndex]['intake'] -=
                    weeklyData[selectedDayIndex]['meals'][mealIndex]['calories']
                        as int;
                weeklyData[selectedDayIndex]['meals'].removeAt(mealIndex);
              });
              _saveMemory();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete 🗑️',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () {
              // SAVE BUTTON
              setState(() {
                int oldCal =
                    weeklyData[selectedDayIndex]['meals'][mealIndex]['calories']
                        as int;
                int newCal = int.tryParse(calController.text) ?? oldCal;
                weeklyData[selectedDayIndex]['meals'][mealIndex] = {
                  'name': nameController.text,
                  'calories': newCal,
                };
                weeklyData[selectedDayIndex]['intake'] +=
                    (newCal - oldCal); // Update the bar height!
              });
              _saveMemory();
              Navigator.pop(context);
            },
            child: const Text(
              'Save 🪄',
              style: TextStyle(color: Color(0xFFCE93D8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    _checkMidnightReset();

    int todaysGoal = calculateDailyGoal();
    // Always show the selected day's remaining allowance
    int remainingCalories =
        todaysGoal - (weeklyData[selectedDayIndex]['intake'] as int);

    double maxIntake = 2100.0;
    double goalHeightFactor =
        (todaysGoal > maxIntake ? maxIntake : todaysGoal) / maxIntake;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✨ Elsa\'s Journey ✨',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Energy Card
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
                      'Today\'s Allowance 🦇',
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

            // The INTERACTIVE Graph 📊
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
                      'Tap a day to view/edit! 💜',
                      style: TextStyle(
                        fontSize: 16,
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
                          // 🪄 The Subtle Phantom Limit Line!
                          Positioned(
                            // +24 pushes the line up to account for the text sitting under the bars!
                            bottom: (100 * goalHeightFactor) + 24,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: const Color(0xFF4A306D).withOpacity(
                                0.25,
                              ), // A very soft, translucent dark purple
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: weeklyData.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var data = entry.value;
                              double rawHeight = data['intake'] / maxIntake;
                              double heightFactor = rawHeight > 1.0
                                  ? 1.0
                                  : rawHeight;
                              bool isSelected = idx == selectedDayIndex;

                              // 💔 The Sad Color Logic
                              bool wentOverLimit = data['intake'] > todaysGoal;
                              Color barColor;

                              if (wentOverLimit) {
                                barColor = Colors
                                    .grey[600]!; // A sad, lifeless, drained grey
                              } else if (isSelected) {
                                barColor = const Color(
                                  0xFFE1BEE7,
                                ); // Bright magical highlight
                              } else {
                                barColor = const Color(
                                  0xFF7B1FA2,
                                ); // Happy Kuromi purple!
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDayIndex = idx;
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: isSelected ? 24 : 20,
                                      height: 100 * heightFactor,
                                      decoration: BoxDecoration(
                                        color:
                                            barColor, // 🪄 Cast the new dynamic color!
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(5),
                                            ),
                                        border: isSelected
                                            ? Border.all(
                                                color: const Color(0xFF4A306D),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['day'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? const Color(0xFF7B1FA2)
                                            : Colors.black54,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
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

            // Timeline & Weight
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4A306D),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
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
                            '${calculateDaysLeft()}', // <-- 🪄 Calls the math directly! No variables needed!
                            style: const TextStyle(
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

            // Dynamic Spellbook List 📓🦇
            Text(
              '  ${weeklyData[selectedDayIndex]['day']}\'s Spellbook 📓 (Tap to Edit)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A306D),
              ),
            ),
            const SizedBox(height: 10),
            (weeklyData[selectedDayIndex]['meals'] as List).isEmpty
                ? Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No magic consumed on this day! 🌸',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        (weeklyData[selectedDayIndex]['meals'] as List).length,
                    itemBuilder: (context, index) {
                      final meal = weeklyData[selectedDayIndex]['meals'][index];
                      return GestureDetector(
                        onTap: () => _showEditDeleteDialog(index),
                        child: Card(
                          color: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.edit,
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
              weeklyData[selectedDayIndex]['meals'].add(result);
              weeklyData[selectedDayIndex]['intake'] +=
                  result['calories'] as int;
            });
            _saveMemory();
            _checkMidnightReset();
          }
        },
        backgroundColor: const Color(0xFF4A306D),
        icon: const Icon(Icons.add, color: Colors.white),
        // The button label magically changes to whichever day you tapped!
        label: Text(
          'Log for ${weeklyData[selectedDayIndex]['day']}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
