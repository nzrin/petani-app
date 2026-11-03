import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/chatbot/views/chatbot_view.dart';
import 'package:petani/core/theme/app_theme.dart';

void main() {
  testWidgets('chatbot uses tap-only choices and opens nested task options', (
    tester,
  ) async {
    var addTaskCalls = 0;
    var loadTaskCalls = 0;
    final completedTaskIds = <int>[];
    final openedTaskIds = <int>[];
    final task = ChatbotTaskItem(
      id: 77,
      plotId: 12,
      title: 'Membaja',
      projectName: 'Projek Nanas',
      plotName: 'Plot 002',
      contextLabel: 'Projek Nanas · Plot 002',
      scheduledAt: DateTime(2026, 9, 27, 11, 55),
      imagePath: 'assets/images/tasks/fertilizing.png',
      canComplete: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChatbotView(
          onAddTask: () async => addTaskCalls++,
          onLoadIncompleteTasks: () async {
            loadTaskCalls++;
            return [task];
          },
          onCompleteTask: (task) async => completedTaskIds.add(task.id),
          onSetTaskControlMethod: (_, _) async => true,
          onOpenTaskDetail: (task) async => openedTaskIds.add(task.id),
          onAddPlot: () async {},
          onAddProject: () async {},
          onLoadProjects: () async => const [],
          onOpenProjectDetail: (_) async {},
          onLoadPlots: () async => const [],
          onOpenPlotDetail: (_) async {},
        ),
      ),
    );

    expect(find.byKey(const Key('chatbot-view')), findsOneWidget);
    expect(
      find.text('Apa yang boleh saya bantu anda hari ini?'),
      findsOneWidget,
    );
    expect(find.text('Sahabat Petani'), findsOneWidget);
    expect(find.text('Hai! Saya Sahabat Petani.'), findsOneWidget);
    expect(find.text('APA YANG ANDA INGIN BUAT HARI INI?'), findsOneWidget);
    expect(find.byKey(const Key('chatbot-add-project-option')), findsOneWidget);
    expect(find.byKey(const Key('chatbot-add-task-option')), findsOneWidget);
    expect(find.byKey(const Key('chatbot-add-plot-option')), findsOneWidget);
    expect(find.text('Berkenaan Tugasan'), findsOneWidget);
    expect(find.text('Berkenaan Projek'), findsOneWidget);
    expect(find.text('Berkenaan Plot'), findsOneWidget);
    expect(find.text('Tambah Tugasan Baru'), findsNothing);
    expect(find.text('Tambah Projek'), findsNothing);
    expect(find.text('Tambah Plot'), findsNothing);
    expect(find.text('Tunjuk Laporan'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);

    String optionImageAsset(Key key) {
      final image = tester.widget<Image>(
        find.descendant(of: find.byKey(key), matching: find.byType(Image)),
      );
      return (image.image as AssetImage).assetName;
    }

    Color optionBackgroundColor(Key key) {
      return tester
          .widget<Material>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Material),
            ),
          )
          .color!;
    }

    const softBrown = Color(0xFFF0E7D8);
    expect(
      optionBackgroundColor(const Key('chatbot-add-project-option')),
      softBrown,
    );
    expect(
      optionBackgroundColor(const Key('chatbot-add-task-option')),
      softBrown,
    );
    expect(
      optionBackgroundColor(const Key('chatbot-add-plot-option')),
      softBrown,
    );

    expect(
      optionImageAsset(const Key('chatbot-add-project-option')),
      'assets/images/farmer_project_add.png',
    );
    expect(
      optionImageAsset(const Key('chatbot-add-task-option')),
      'assets/images/farmer_task.png',
    );
    expect(
      optionImageAsset(const Key('chatbot-add-plot-option')),
      'assets/images/farmer_plot_add.png',
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('chatbot-add-project-option'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('chatbot-add-task-option'))).dy,
      ),
    );

    await tester.tap(find.byKey(const Key('chatbot-add-task-option')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatbot-create-task-option')), findsOneWidget);
    expect(
      find.byKey(const Key('chatbot-complete-task-option')),
      findsOneWidget,
    );
    expect(
      optionBackgroundColor(const Key('chatbot-create-task-option')),
      softBrown,
    );
    expect(
      optionBackgroundColor(const Key('chatbot-complete-task-option')),
      softBrown,
    );
    expect(
      optionBackgroundColor(const Key('chatbot-back-to-main-option')),
      isNot(softBrown),
    );
    expect(
      find.text('Baik. Apa yang anda mahu lakukan dengan tugasan?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chatbot-create-task-option')));
    await tester.pumpAndSettle();

    expect(addTaskCalls, 1);
    expect(loadTaskCalls, 0);
    expect(find.byKey(const Key('chatbot-add-task-option')), findsOneWidget);
    expect(
      find.text('Ada lagi yang boleh saya bantu? Pilih sahaja di bawah.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chatbot-add-task-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatbot-complete-task-option')));
    await tester.pumpAndSettle();

    expect(loadTaskCalls, 1);
    final taskChoice = find.byKey(const Key('chatbot-task-choice-77'));
    expect(
      find.descendant(
        of: find.byKey(const Key('chatbot-message-list')),
        matching: taskChoice,
      ),
      findsOneWidget,
    );
    expect(find.text('Pilih tugasan dalam perbualan di atas'), findsOneWidget);

    await tester.tap(taskChoice);
    await tester.pumpAndSettle();

    expect(completedTaskIds, [77]);
    expect(
      find.text('Selesai! Berikut ialah maklumat tugasan anda.'),
      findsOneWidget,
    );
    expect(find.text('Tekan untuk lihat butiran'), findsWidgets);

    await tester.tap(find.byKey(const Key('chatbot-completed-task-card-77')));
    await tester.pumpAndSettle();
    expect(openedTaskIds, [77]);
  });

  testWidgets(
    'missing control method is selected in chat before completing task',
    (tester) async {
      final selectedMethods = <ChatbotControlMethod>[];
      final completedTaskIds = <int>[];
      final task = ChatbotTaskItem(
        id: 88,
        plotId: 14,
        title: 'Kawalan Serangga',
        projectName: 'Projek Cili',
        plotName: 'Plot A',
        contextLabel: 'Projek Cili · Plot A',
        scheduledAt: DateTime(2026, 9, 28, 9),
        imagePath: 'assets/images/tasks/insect_control.png',
        canComplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChatbotView(
            onAddTask: () async {},
            onLoadIncompleteTasks: () async => [task],
            onCompleteTask: (task) async => completedTaskIds.add(task.id),
            onSetTaskControlMethod: (task, method) async {
              selectedMethods.add(method);
              return true;
            },
            onOpenTaskDetail: (_) async {},
            onAddPlot: () async {},
            onAddProject: () async {},
            onLoadProjects: () async => const [],
            onOpenProjectDetail: (_) async {},
            onLoadPlots: () async => const [],
            onOpenPlotDetail: (_) async {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('chatbot-add-task-option')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatbot-complete-task-option')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatbot-task-choice-88')));
      await tester.pumpAndSettle();

      final organicOption = find.byKey(
        const Key('chatbot-control-method-organic-88'),
      );
      final chemicalOption = find.byKey(
        const Key('chatbot-control-method-chemical-88'),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('chatbot-message-list')),
          matching: organicOption,
        ),
        findsOneWidget,
      );
      expect(chemicalOption, findsOneWidget);
      expect(find.text('Organik'), findsOneWidget);
      expect(find.text('Kimia'), findsOneWidget);

      await tester.tap(organicOption);
      await tester.pumpAndSettle();

      expect(selectedMethods, [ChatbotControlMethod.organic]);
      expect(completedTaskIds, [88]);
      expect(
        find.byKey(const Key('chatbot-completed-task-card-88')),
        findsOneWidget,
      );
    },
  );

  testWidgets('project and plot choices open selectable conversation lists', (
    tester,
  ) async {
    final openedProjectKeys = <String>[];
    final openedPlotIds = <int>[];
    const project = ChatbotProjectItem(
      key: 'projek-a',
      name: 'Projek Bandar Baru',
      location: 'Kuala Nerus',
      cropNames: ['Nanas'],
      plotCount: 1,
      imagePath: '',
    );
    const plot = ChatbotPlotItem(
      id: 22,
      projectKey: 'projek-a',
      projectName: 'Projek Bandar Baru',
      name: 'Plot 002',
      cropName: 'Nanas',
      rowSummary: '8 batas',
      imagePath: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChatbotView(
          onAddTask: () async {},
          onLoadIncompleteTasks: () async => const [],
          onCompleteTask: (_) async {},
          onSetTaskControlMethod: (_, _) async => true,
          onOpenTaskDetail: (_) async {},
          onAddPlot: () async {},
          onAddProject: () async {},
          onLoadProjects: () async => const [project],
          onOpenProjectDetail: (project) async {
            openedProjectKeys.add(project.key);
          },
          onLoadPlots: () async => const [plot],
          onOpenPlotDetail: (plot) async => openedPlotIds.add(plot.id),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chatbot-add-project-option')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chatbot-create-project-option')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chatbot-view-projects-option')),
      findsOneWidget,
    );
    expect(find.text('Lihat Projek'), findsOneWidget);
    expect(find.text('Lihat Semua Projek'), findsNothing);

    await tester.tap(find.byKey(const Key('chatbot-view-projects-option')));
    await tester.pumpAndSettle();
    final projectChoice = find.byKey(
      const Key('chatbot-project-choice-projek-a'),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('chatbot-message-list')),
        matching: projectChoice,
      ),
      findsOneWidget,
    );
    await tester.tap(projectChoice);
    await tester.pumpAndSettle();
    expect(openedProjectKeys, ['projek-a']);

    await tester.tap(find.byKey(const Key('chatbot-add-plot-option')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatbot-create-plot-option')), findsOneWidget);
    expect(find.byKey(const Key('chatbot-view-plots-option')), findsOneWidget);
    expect(find.text('Lihat Plot'), findsOneWidget);
    expect(
      find.text('Boleh. Pilih tindakan plot yang anda perlukan.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('chatbot-view-plots-option')));
    await tester.pumpAndSettle();
    final plotChoice = find.byKey(const Key('chatbot-plot-choice-22'));
    expect(
      find.descendant(
        of: find.byKey(const Key('chatbot-message-list')),
        matching: plotChoice,
      ),
      findsOneWidget,
    );
    await tester.tap(plotChoice);
    await tester.pumpAndSettle();
    expect(openedPlotIds, [22]);
  });
}
