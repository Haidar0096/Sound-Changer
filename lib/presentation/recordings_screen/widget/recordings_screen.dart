import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voice_changer/configuration/service_locator.dart';
import 'package:voice_changer/presentation/recordings_screen/bloc/player_bloc/player_bloc.dart';
import 'package:voice_changer/presentation/recordings_screen/bloc/recordings_bloc/recordings_bloc.dart';
import 'package:voice_changer/presentation/styles/styles.dart';

part 'error_widget.dart';

part 'loading_widget.dart';

part 'recordings_screen_components.dart';
part 'recording_card.dart';
part 'dismissible_tile.dart';
part 'recording_tile_contents.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({Key? key}) : super(key: key);

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen>
    with WidgetsBindingObserver {
  final Logger _logger = serviceLocator.get<Logger>(param1: Level.nothing);

  late final RecordingsBloc _recordingsBloc;
  late final PlayerBloc _playerBloc;

  @override
  initState() {
    super.initState();
    _recordingsBloc = serviceLocator.get<RecordingsBloc>()
      ..add(const RecordingsBlocEvent.init());
    _playerBloc = serviceLocator.get<PlayerBloc>()
      ..add(const PlayerBlocEvent.init());
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _logger.d('app inactive');
        _playerBloc.add(const PlayerBlocEvent.appGoInactive());
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => _recordingsBloc,
        ),
        BlocProvider(
          create: (_) => _playerBloc,
        ),
      ],
      child: Builder(
        builder: (context) => BlocBuilder<RecordingsBloc, RecordingsBlocState>(
          builder: (context, recordingsBlocState) =>
              BlocBuilder<PlayerBloc, PlayerBlocState>(
            builder: (context, playerBlocState) {
              if (playerBlocState.isError || recordingsBlocState.isError) {
                return _ErrorWidget();
              } else {
                return StreamBuilder<PlayerInfo>(
                  stream: playerBlocState.playerInfoStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data!.state.isInitialized &&
                        !recordingsBlocState.isProcessing) {
                      return const _RecordingsScreenComponents();
                    } else {
                      return const _LoadingWidget();
                    }
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
