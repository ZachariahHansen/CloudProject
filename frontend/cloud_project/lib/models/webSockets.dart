class _LobbyPageState extends State<LobbyPage> {
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://your-websocket-url.com/Prod?lobbyId=${widget.lobbyId}&userId=${widget.userId}'),
    );
  }
}