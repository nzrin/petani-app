import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';

typedef ChatbotAction = Future<void> Function();
typedef ChatbotTaskLoader = Future<List<ChatbotTaskItem>> Function();
typedef ChatbotTaskCompleter = Future<void> Function(ChatbotTaskItem task);
typedef ChatbotTaskControlMethodSetter =
    Future<bool> Function(ChatbotTaskItem task, ChatbotControlMethod method);
typedef ChatbotTaskOpener = Future<void> Function(ChatbotTaskItem task);
typedef ChatbotProjectLoader = Future<List<ChatbotProjectItem>> Function();
typedef ChatbotProjectOpener =
    Future<void> Function(ChatbotProjectItem project);
typedef ChatbotPlotLoader = Future<List<ChatbotPlotItem>> Function();
typedef ChatbotPlotOpener = Future<void> Function(ChatbotPlotItem plot);

const _chatOptionSoftBrown = Color(0xFFF0E7D8);

enum ChatbotControlMethod {
  organic('Organik'),
  chemical('Kimia');

  const ChatbotControlMethod(this.label);

  final String label;
}

class ChatbotTaskItem {
  const ChatbotTaskItem({
    required this.id,
    required this.plotId,
    required this.title,
    required this.projectName,
    required this.plotName,
    required this.contextLabel,
    required this.scheduledAt,
    required this.imagePath,
    required this.canComplete,
  });

  final int id;
  final int plotId;
  final String title;
  final String projectName;
  final String plotName;
  final String contextLabel;
  final DateTime scheduledAt;
  final String imagePath;
  final bool canComplete;
}

class ChatbotProjectItem {
  const ChatbotProjectItem({
    required this.key,
    required this.name,
    required this.location,
    required this.cropNames,
    required this.plotCount,
    required this.imagePath,
  });

  final String key;
  final String name;
  final String location;
  final List<String> cropNames;
  final int plotCount;
  final String imagePath;
}

class ChatbotPlotItem {
  const ChatbotPlotItem({
    required this.id,
    required this.projectKey,
    required this.projectName,
    required this.name,
    required this.cropName,
    required this.rowSummary,
    required this.imagePath,
  });

  final int id;
  final String projectKey;
  final String projectName;
  final String name;
  final String cropName;
  final String rowSummary;
  final String imagePath;
}

class ChatbotView extends StatefulWidget {
  const ChatbotView({
    required this.onAddTask,
    required this.onLoadIncompleteTasks,
    required this.onCompleteTask,
    required this.onSetTaskControlMethod,
    required this.onOpenTaskDetail,
    required this.onAddPlot,
    required this.onAddProject,
    required this.onLoadProjects,
    required this.onOpenProjectDetail,
    required this.onLoadPlots,
    required this.onOpenPlotDetail,
    super.key,
  });

  final ChatbotAction onAddTask;
  final ChatbotTaskLoader onLoadIncompleteTasks;
  final ChatbotTaskCompleter onCompleteTask;
  final ChatbotTaskControlMethodSetter onSetTaskControlMethod;
  final ChatbotTaskOpener onOpenTaskDetail;
  final ChatbotAction onAddPlot;
  final ChatbotAction onAddProject;
  final ChatbotProjectLoader onLoadProjects;
  final ChatbotProjectOpener onOpenProjectDetail;
  final ChatbotPlotLoader onLoadPlots;
  final ChatbotPlotOpener onOpenPlotDetail;

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(text: 'Hai! Saya Sahabat Petani.'),
    _ChatMessage(text: 'Apa yang boleh saya bantu anda hari ini?'),
  ].toList();

  _ChatMenu _menu = _ChatMenu.main;
  bool _isRunningAction = false;
  final Set<int> _completedTaskIds = <int>{};
  final Map<int, ChatbotControlMethod> _selectedControlMethods =
      <int, ChatbotControlMethod>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openMenu({
    required String selection,
    required String reply,
    required _ChatMenu menu,
  }) {
    if (_isRunningAction) return;
    setState(() {
      _messages
        ..add(_ChatMessage(text: selection, isUser: true))
        ..add(_ChatMessage(text: reply));
      _menu = menu;
    });
    _scrollToBottom();
  }

  void _showMainMenu() {
    if (_isRunningAction) return;
    setState(() {
      _messages.add(const _ChatMessage(text: 'Kembali ke menu utama.'));
      _menu = _ChatMenu.main;
    });
    _scrollToBottom();
  }

  Future<void> _runAction({
    required String selection,
    required String reply,
    required ChatbotAction action,
    bool closeAfterAction = false,
  }) async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(_ChatMessage(text: selection, isUser: true))
        ..add(_ChatMessage(text: reply));
    });
    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 240));
    await action();
    if (!mounted) return;

    if (closeAfterAction) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isRunningAction = false;
      _menu = _ChatMenu.main;
      _messages.add(
        const _ChatMessage(
          text: 'Ada lagi yang boleh saya bantu? Pilih sahaja di bawah.',
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _showTasksForCompletion() async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(const _ChatMessage(text: 'Selesaikan Tugas', isUser: true))
        ..add(
          const _ChatMessage(
            text: 'Baik, saya semak tugasan yang belum selesai.',
          ),
        );
    });
    _scrollToBottom();

    try {
      final tasks = await widget.onLoadIncompleteTasks();
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        if (tasks.isEmpty) {
          _menu = _ChatMenu.main;
          _messages.add(
            const _ChatMessage(
              text:
                  'Semua tugasan sudah selesai. Tiada tugasan aktif buat masa ini.',
            ),
          );
        } else {
          _menu = _ChatMenu.taskSelection;
          _messages.add(
            _ChatMessage(
              text: 'Pilih tugasan yang anda mahu tandakan selesai.',
              taskOptions: tasks,
            ),
          );
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.tasks;
        _messages.add(
          const _ChatMessage(
            text:
                'Maaf, senarai tugasan tidak dapat dimuatkan. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _showProjects() async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(const _ChatMessage(text: 'Lihat Projek', isUser: true))
        ..add(const _ChatMessage(text: 'Baik, saya semak projek anda.'));
    });
    _scrollToBottom();

    try {
      final projects = await widget.onLoadProjects();
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        if (projects.isEmpty) {
          _menu = _ChatMenu.projects;
          _messages.add(
            const _ChatMessage(text: 'Belum ada projek untuk dipaparkan.'),
          );
        } else {
          _menu = _ChatMenu.projectSelection;
          _messages.add(
            _ChatMessage(
              text: 'Pilih projek yang anda mahu lihat.',
              projectOptions: projects,
            ),
          );
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.projects;
        _messages.add(
          const _ChatMessage(
            text:
                'Maaf, senarai projek tidak dapat dimuatkan. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _showPlots() async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(const _ChatMessage(text: 'Lihat Plot', isUser: true))
        ..add(const _ChatMessage(text: 'Baik, saya semak plot anda.'));
    });
    _scrollToBottom();

    try {
      final plots = await widget.onLoadPlots();
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        if (plots.isEmpty) {
          _menu = _ChatMenu.plots;
          _messages.add(
            const _ChatMessage(text: 'Belum ada plot untuk dipaparkan.'),
          );
        } else {
          _menu = _ChatMenu.plotSelection;
          _messages.add(
            _ChatMessage(
              text: 'Pilih plot yang anda mahu lihat.',
              plotOptions: plots,
            ),
          );
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.plots;
        _messages.add(
          const _ChatMessage(
            text: 'Maaf, senarai plot tidak dapat dimuatkan. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _openProjectDetail(ChatbotProjectItem project) async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(_ChatMessage(text: project.name, isUser: true))
        ..add(const _ChatMessage(text: 'Baik, saya buka butiran projek.'));
    });
    _scrollToBottom();

    try {
      await widget.onOpenProjectDetail(project);
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.main;
        _messages.add(
          const _ChatMessage(
            text: 'Ada lagi yang boleh saya bantu? Pilih sahaja di bawah.',
          ),
        );
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.projectSelection;
        _messages.add(
          const _ChatMessage(
            text: 'Maaf, butiran projek tidak dapat dibuka. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _openPlotDetail(ChatbotPlotItem plot) async {
    if (_isRunningAction) return;
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(
          _ChatMessage(
            text: '${plot.name} — ${plot.projectName}',
            isUser: true,
          ),
        )
        ..add(const _ChatMessage(text: 'Baik, saya buka butiran plot.'));
    });
    _scrollToBottom();

    try {
      await widget.onOpenPlotDetail(plot);
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.main;
        _messages.add(
          const _ChatMessage(
            text: 'Ada lagi yang boleh saya bantu? Pilih sahaja di bawah.',
          ),
        );
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.plotSelection;
        _messages.add(
          const _ChatMessage(
            text: 'Maaf, butiran plot tidak dapat dibuka. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _selectTaskForCompletion(ChatbotTaskItem task) async {
    if (_isRunningAction || _completedTaskIds.contains(task.id)) return;

    final canComplete =
        task.canComplete || _selectedControlMethods.containsKey(task.id);
    if (!canComplete) {
      setState(() {
        _menu = _ChatMenu.controlMethodSelection;
        _messages
          ..add(
            _ChatMessage(
              text: '${task.title} — ${task.contextLabel}',
              isUser: true,
            ),
          )
          ..add(
            _ChatMessage(
              text:
                  'Pilih jenis kawalan untuk tugasan ini. Selepas itu saya akan terus menyelesaikannya.',
              controlMethodTask: task,
            ),
          );
      });
      _scrollToBottom();
      return;
    }

    await _completeTask(
      task,
      addTaskSelection: true,
      assistantText: 'Baik, saya selesaikan tugasan ini.',
    );
  }

  Future<void> _selectControlMethod(
    ChatbotTaskItem task,
    ChatbotControlMethod method,
  ) async {
    if (_isRunningAction || _completedTaskIds.contains(task.id)) return;

    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      _messages
        ..add(_ChatMessage(text: method.label, isUser: true))
        ..add(
          _ChatMessage(
            text: method == ChatbotControlMethod.chemical
                ? 'Baik, pilih produk kimia yang digunakan.'
                : 'Baik, saya simpan pilihan kawalan organik.',
          ),
        );
    });
    _scrollToBottom();

    try {
      final saved = await widget.onSetTaskControlMethod(task, method);
      if (!mounted) return;
      if (!saved) {
        setState(() {
          _isRunningAction = false;
          _menu = _ChatMenu.controlMethodSelection;
          _messages.add(
            const _ChatMessage(
              text:
                  'Pemilihan produk dibatalkan. Anda boleh pilih Organik atau Kimia sekali lagi.',
            ),
          );
        });
        _scrollToBottom();
        return;
      }

      await _completeTask(
        task,
        addTaskSelection: false,
        selectedControlMethod: method,
        assistantText:
            'Jenis kawalan ${method.label} telah disimpan. Saya teruskan menyelesaikan tugasan ini.',
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.controlMethodSelection;
        _messages.add(
          const _ChatMessage(
            text: 'Maaf, jenis kawalan tidak dapat disimpan. Cuba sekali lagi.',
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _completeTask(
    ChatbotTaskItem task, {
    required bool addTaskSelection,
    required String assistantText,
    ChatbotControlMethod? selectedControlMethod,
  }) async {
    setState(() {
      _isRunningAction = true;
      _menu = _ChatMenu.busy;
      if (selectedControlMethod != null) {
        _selectedControlMethods[task.id] = selectedControlMethod;
      }
      if (addTaskSelection) {
        _messages.add(
          _ChatMessage(
            text: '${task.title} — ${task.contextLabel}',
            isUser: true,
          ),
        );
      }
      _messages.add(_ChatMessage(text: assistantText));
    });
    _scrollToBottom();

    try {
      await widget.onCompleteTask(task);
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _completedTaskIds.add(task.id);
        _menu = _ChatMenu.main;
        _messages.add(
          _ChatMessage(
            text: 'Selesai! Berikut ialah maklumat tugasan anda.',
            completedTask: task,
          ),
        );
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isRunningAction = false;
        _menu = _ChatMenu.taskSelection;
        _messages.add(
          const _ChatMessage(
            text: 'Maaf, tugasan tidak dapat diselesaikan. Cuba sekali lagi.',
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Future<void> _openTaskDetail(ChatbotTaskItem task) async {
    if (_isRunningAction) return;
    await widget.onOpenTaskDetail(task);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chatbot-view'),
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4E9),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('chatbot-close-button'),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Tutup',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 4,
        title: const Row(
          children: [
            _AssistantAvatar(size: 48),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sahabat Petani',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Pilih bantuan yang diperlukan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                key: const Key('chatbot-message-list'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _MessageBubble(
                  message: _messages[index],
                  completedTaskIds: _completedTaskIds,
                  selectedControlMethods: _selectedControlMethods,
                  onTaskSelected: _selectTaskForCompletion,
                  onControlMethodSelected: _selectControlMethod,
                  onTaskDetail: _openTaskDetail,
                  onProjectSelected: _openProjectDetail,
                  onPlotSelected: _openPlotDetail,
                  showAvatar:
                      !_messages[index].isUser &&
                      (index == 0 || _messages[index - 1].isUser),
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFCF5),
                border: Border(top: BorderSide(color: Color(0xFFE8E0CF))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x120B3D2E),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.56,
                  ),
                  child: SingleChildScrollView(
                    key: const Key('chatbot-option-scroll'),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildOptions(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return switch (_menu) {
      _ChatMenu.main => _OptionGroup(
        key: const ValueKey<String>('chatbot-main-menu'),
        caption: 'APA YANG ANDA INGIN BUAT HARI INI?',
        options: [
          _ChatOption(
            key: const Key('chatbot-add-project-option'),
            imagePath: 'assets/images/farmer_project_add.png',
            title: 'Berkenaan Projek',
            subtitle: 'Mulakan projek tanaman baharu',
            color: const Color(0xFF8A6313),
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _openMenu(
              selection: 'Berkenaan Projek',
              reply: 'Baik. Apa yang anda mahu lakukan dengan projek?',
              menu: _ChatMenu.projects,
            ),
          ),
          _ChatOption(
            key: const Key('chatbot-add-task-option'),
            imagePath: 'assets/images/farmer_task.png',
            title: 'Berkenaan Tugasan',
            subtitle: 'Buat atau selesaikan tugasan',
            color: AppColors.green,
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _openMenu(
              selection: 'Berkenaan Tugasan',
              reply: 'Baik. Apa yang anda mahu lakukan dengan tugasan?',
              menu: _ChatMenu.tasks,
            ),
          ),
          _ChatOption(
            key: const Key('chatbot-add-plot-option'),
            imagePath: 'assets/images/farmer_plot_add.png',
            title: 'Berkenaan Plot',
            subtitle: 'Urus plot atau projek tanaman',
            color: const Color(0xFF735E45),
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _openMenu(
              selection: 'Berkenaan Plot',
              reply: 'Boleh. Pilih tindakan plot yang anda perlukan.',
              menu: _ChatMenu.plots,
            ),
          ),
        ],
      ),
      _ChatMenu.projects => _OptionGroup(
        key: const ValueKey<String>('chatbot-project-menu'),
        caption: 'Pilihan projek',
        options: [
          _ChatOption(
            key: const Key('chatbot-create-project-option'),
            icon: Icons.create_new_folder_rounded,
            title: 'Buat Projek Baharu',
            subtitle: 'Pilih tanaman dan masukkan butiran projek',
            color: AppColors.green,
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _runAction(
              selection: 'Buat Projek Baharu',
              reply: 'Baik, mari pilih tanaman untuk projek baharu.',
              action: widget.onAddProject,
            ),
          ),
          _ChatOption(
            key: const Key('chatbot-view-projects-option'),
            icon: Icons.folder_open_rounded,
            title: 'Lihat Projek',
            subtitle: 'Pilih projek untuk melihat butiran',
            color: const Color(0xFF8A6313),
            backgroundColor: _chatOptionSoftBrown,
            onTap: _showProjects,
          ),
          _backOption(),
        ],
      ),
      _ChatMenu.tasks => _OptionGroup(
        key: const ValueKey<String>('chatbot-task-menu'),
        caption: 'Pilihan tugasan',
        options: [
          _ChatOption(
            key: const Key('chatbot-create-task-option'),
            icon: Icons.add_task_rounded,
            title: 'Buat Tugasan Sekarang',
            subtitle: 'Pilih projek, plot dan butiran tugasan',
            color: AppColors.green,
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _runAction(
              selection: 'Buat Tugasan Sekarang',
              reply: 'Baik, saya bukakan borang tugasan untuk anda.',
              action: widget.onAddTask,
            ),
          ),
          _ChatOption(
            key: const Key('chatbot-complete-task-option'),
            icon: Icons.task_alt_rounded,
            title: 'Selesaikan Tugas',
            subtitle: 'Pilih tugasan untuk ditandakan selesai',
            color: const Color(0xFF8A6313),
            backgroundColor: _chatOptionSoftBrown,
            onTap: _showTasksForCompletion,
          ),
          _backOption(),
        ],
      ),
      _ChatMenu.plots => _OptionGroup(
        key: const ValueKey<String>('chatbot-plot-menu'),
        caption: 'Pilihan plot dan projek',
        options: [
          _ChatOption(
            key: const Key('chatbot-create-plot-option'),
            icon: Icons.add_location_alt_rounded,
            title: 'Tambah Plot pada Projek',
            subtitle: 'Gunakan projek yang sudah tersedia',
            color: const Color(0xFF735E45),
            backgroundColor: _chatOptionSoftBrown,
            onTap: () => _runAction(
              selection: 'Tambah Plot pada Projek',
              reply: 'Baik, saya bukakan borang plot untuk anda.',
              action: widget.onAddPlot,
            ),
          ),
          _ChatOption(
            key: const Key('chatbot-view-plots-option'),
            icon: Icons.grid_view_rounded,
            title: 'Lihat Plot',
            subtitle: 'Pilih plot untuk melihat butiran',
            color: const Color(0xFF8A6313),
            backgroundColor: _chatOptionSoftBrown,
            onTap: _showPlots,
          ),
          _backOption(),
        ],
      ),
      _ChatMenu.busy => const _BusyOptions(
        key: ValueKey<String>('chatbot-busy-menu'),
      ),
      _ChatMenu.taskSelection => _TaskSelectionHint(
        key: const ValueKey<String>('chatbot-task-selection-menu'),
        message: 'Pilih tugasan dalam perbualan di atas',
        onBack: _showMainMenu,
      ),
      _ChatMenu.controlMethodSelection => _TaskSelectionHint(
        key: const ValueKey<String>('chatbot-control-method-selection-menu'),
        message: 'Pilih Organik atau Kimia dalam perbualan',
        onBack: _showMainMenu,
      ),
      _ChatMenu.projectSelection => _TaskSelectionHint(
        key: const ValueKey<String>('chatbot-project-selection-menu'),
        message: 'Pilih projek dalam perbualan di atas',
        onBack: _showMainMenu,
      ),
      _ChatMenu.plotSelection => _TaskSelectionHint(
        key: const ValueKey<String>('chatbot-plot-selection-menu'),
        message: 'Pilih plot dalam perbualan di atas',
        onBack: _showMainMenu,
      ),
    };
  }

  _ChatOption _backOption() {
    return _ChatOption(
      key: const Key('chatbot-back-to-main-option'),
      icon: Icons.arrow_back_rounded,
      title: 'Kembali ke Menu Utama',
      subtitle: 'Pilih bantuan yang lain',
      color: AppColors.muted,
      backgroundColor: const Color(0xFFF0F1EC),
      onTap: _showMainMenu,
    );
  }
}

enum _ChatMenu {
  main,
  projects,
  tasks,
  plots,
  taskSelection,
  controlMethodSelection,
  projectSelection,
  plotSelection,
  busy,
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    this.isUser = false,
    this.taskOptions = const [],
    this.projectOptions = const [],
    this.plotOptions = const [],
    this.controlMethodTask,
    this.completedTask,
  });

  final String text;
  final bool isUser;
  final List<ChatbotTaskItem> taskOptions;
  final List<ChatbotProjectItem> projectOptions;
  final List<ChatbotPlotItem> plotOptions;
  final ChatbotTaskItem? controlMethodTask;
  final ChatbotTaskItem? completedTask;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showAvatar,
    required this.completedTaskIds,
    required this.selectedControlMethods,
    required this.onTaskSelected,
    required this.onControlMethodSelected,
    required this.onTaskDetail,
    required this.onProjectSelected,
    required this.onPlotSelected,
  });

  final _ChatMessage message;
  final bool showAvatar;
  final Set<int> completedTaskIds;
  final Map<int, ChatbotControlMethod> selectedControlMethods;
  final ValueChanged<ChatbotTaskItem> onTaskSelected;
  final void Function(ChatbotTaskItem, ChatbotControlMethod)
  onControlMethodSelected;
  final ValueChanged<ChatbotTaskItem> onTaskDetail;
  final ValueChanged<ChatbotProjectItem> onProjectSelected;
  final ValueChanged<ChatbotPlotItem> onPlotSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            if (showAvatar)
              const _AssistantAvatar(size: 28)
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    message.taskOptions.isEmpty &&
                        message.projectOptions.isEmpty &&
                        message.plotOptions.isEmpty &&
                        message.controlMethodTask == null &&
                        message.completedTask == null
                    ? 290
                    : 340,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.green : Colors.white,
                border: message.isUser
                    ? null
                    : Border.all(color: const Color(0xFFE9E1D2)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D4C3A25),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : AppColors.ink,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.taskOptions.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    ...message.taskOptions.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ConversationTaskCard(
                          key: ValueKey<String>(
                            'chatbot-task-choice-${task.id}',
                          ),
                          task: task,
                          isCompleted: completedTaskIds.contains(task.id),
                          canComplete:
                              task.canComplete ||
                              selectedControlMethods.containsKey(task.id),
                          onTap: () => completedTaskIds.contains(task.id)
                              ? onTaskDetail(task)
                              : onTaskSelected(task),
                        ),
                      ),
                    ),
                  ],
                  if (message.projectOptions.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    ...message.projectOptions.map(
                      (project) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ConversationProjectCard(
                          key: ValueKey<String>(
                            'chatbot-project-choice-${project.key}',
                          ),
                          project: project,
                          onTap: () => onProjectSelected(project),
                        ),
                      ),
                    ),
                  ],
                  if (message.plotOptions.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    ...message.plotOptions.map(
                      (plot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ConversationPlotCard(
                          key: ValueKey<String>(
                            'chatbot-plot-choice-${plot.id}',
                          ),
                          plot: plot,
                          onTap: () => onPlotSelected(plot),
                        ),
                      ),
                    ),
                  ],
                  if (message.controlMethodTask case final task?) ...[
                    const SizedBox(height: 11),
                    _ControlMethodChoices(
                      task: task,
                      selectedMethod: selectedControlMethods[task.id],
                      onSelected: (method) =>
                          onControlMethodSelected(task, method),
                    ),
                  ],
                  if (message.completedTask case final task?) ...[
                    const SizedBox(height: 11),
                    _ConversationTaskCard(
                      key: ValueKey<String>(
                        'chatbot-completed-task-card-${task.id}',
                      ),
                      task: task,
                      isCompleted: true,
                      canComplete: true,
                      onTap: () => onTaskDetail(task),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationProjectCard extends StatelessWidget {
  const _ConversationProjectCard({
    required this.project,
    required this.onTap,
    super.key,
  });

  final ChatbotProjectItem project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cropLabel = project.cropNames.join(', ');
    return Material(
      color: _chatOptionSoftBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDFD1BC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 11, 9, 11),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 46,
                child: project.imagePath.isEmpty
                    ? const Icon(
                        Icons.business_center_rounded,
                        color: AppColors.green,
                        size: 28,
                      )
                    : Image.asset(project.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (project.location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _ConversationCardMeta(
                        icon: Icons.location_on_outlined,
                        label: project.location,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _ConversationCardMeta(
                      icon: Icons.grid_view_rounded,
                      label:
                          '${project.plotCount} plot${cropLabel.isEmpty ? '' : ' · $cropLabel'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A6313),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationPlotCard extends StatelessWidget {
  const _ConversationPlotCard({
    required this.plot,
    required this.onTap,
    super.key,
  });

  final ChatbotPlotItem plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _chatOptionSoftBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDFD1BC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 11, 9, 11),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 46,
                child: plot.imagePath.isEmpty
                    ? const Icon(
                        Icons.grass_rounded,
                        color: AppColors.green,
                        size: 28,
                      )
                    : Image.asset(plot.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _ConversationCardMeta(
                      icon: Icons.business_center_outlined,
                      label: plot.projectName,
                    ),
                    const SizedBox(height: 4),
                    _ConversationCardMeta(
                      icon: Icons.eco_outlined,
                      label: '${plot.cropName} · ${plot.rowSummary}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A6313),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationCardMeta extends StatelessWidget {
  const _ConversationCardMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationTaskCard extends StatelessWidget {
  const _ConversationTaskCard({
    required this.task,
    required this.isCompleted,
    required this.canComplete,
    required this.onTap,
    super.key,
  });

  final ChatbotTaskItem task;
  final bool isCompleted;
  final bool canComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isCompleted
        ? const Color(0xFFDDEEDF)
        : const Color(0xFFF8F4E9);
    final accentColor = isCompleted
        ? AppColors.green
        : canComplete
        ? const Color(0xFF8A6313)
        : AppColors.muted;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? const Color(0xFFB9D9BE)
              : const Color(0xFFE4DAC8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 9, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 44,
                child: Image.asset(task.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_formatTaskDate(task.scheduledAt)} · '
                            '${formatMalayTime(task.scheduledAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!canComplete && !isCompleted) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Jenis kawalan belum lengkap',
                        style: TextStyle(
                          color: Color(0xFF9A5B2D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Tekan untuk lihat butiran',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : canComplete
                    ? Icons.chevron_right_rounded
                    : Icons.info_outline_rounded,
                color: accentColor,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlMethodChoices extends StatelessWidget {
  const _ControlMethodChoices({
    required this.task,
    required this.selectedMethod,
    required this.onSelected,
  });

  final ChatbotTaskItem task;
  final ChatbotControlMethod? selectedMethod;
  final ValueChanged<ChatbotControlMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final method in ChatbotControlMethod.values) ...[
          if (method.index > 0) const SizedBox(width: 8),
          Expanded(
            child: _ControlMethodButton(
              key: ValueKey<String>(
                'chatbot-control-method-${method.name}-${task.id}',
              ),
              method: method,
              selected: selectedMethod == method,
              enabled: selectedMethod == null,
              onTap: () => onSelected(method),
            ),
          ),
        ],
      ],
    );
  }
}

class _ControlMethodButton extends StatelessWidget {
  const _ControlMethodButton({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final ChatbotControlMethod method;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.green;
    return Material(
      color: selected ? AppColors.green : AppColors.mint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                method == ChatbotControlMethod.organic
                    ? Icons.eco_rounded
                    : Icons.science_rounded,
                color: foreground,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  method.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTaskDate(DateTime value) {
  final date = value.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ogo',
    'Sep',
    'Okt',
    'Nov',
    'Dis',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icon_head_1000.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.caption, required this.options, super.key});

  final String caption;
  final List<_ChatOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            caption,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        ...options.map(
          (option) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: option),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: AppColors.muted),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Tekan pilihan',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatOption extends StatelessWidget {
  const _ChatOption({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.icon,
    this.imagePath,
    super.key,
  }) : assert(icon != null || imagePath != null);

  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: imagePath == null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(icon, color: color, size: 23),
                      )
                    : Image.asset(imagePath!, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyOptions extends StatelessWidget {
  const _BusyOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 78,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.green,
              ),
            ),
            SizedBox(height: 9),
            Text(
              'Membuka pilihan…',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSelectionHint extends StatelessWidget {
  const _TaskSelectionHint({
    required this.message,
    required this.onBack,
    super.key,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.touch_app_rounded, color: AppColors.green, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          key: const Key('chatbot-task-selection-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: const Text('Menu'),
          style: TextButton.styleFrom(foregroundColor: AppColors.green),
        ),
      ],
    );
  }
}
