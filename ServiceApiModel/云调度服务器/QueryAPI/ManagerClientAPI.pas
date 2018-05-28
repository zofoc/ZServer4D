unit ManagerClientAPI;

interface

uses CoreClasses, TextDataEngine, ListEngine, CommunicationFramework,
  DoStatusIO, UnicodeMixedLib, DataFrameEngine,
  CommunicationFrameworkDoubleTunnelIO_ServMan;

type
  TQueryResultInfo = record
    RegName: string;
    Host: string;
    RecvPort, SendPort: WORD;
    WorkLoad: Integer;
    ServerType: TServerType;
    procedure Init;
  end;

  TManagerQueryProc = reference to procedure(const State: Boolean; const Addr: TQueryResultInfo);

  TManagerQuery = class
  private
    ClientIntf: TCommunicationFrameworkClient;
  public
    ServerList: TGenericsList<TQueryResultInfo>;

    constructor Create(AClientIntf: TCommunicationFrameworkClient);
    destructor Destroy; override;

    procedure Connect(Addr: string; Port: WORD); virtual;

    // ����ʽ��ѯȫ�ַ����������صĲ�ѯ�����ServerList��
    procedure WaitQuery(Addr: string; QueryType: TServerType);
    // �첽ʽ��ѯȫ�ַ�������ResultProc�¼�������ʱ��ʾ�첽��ѯ�Ѿ���ɣ����ز�ѯ�����ServerList�У�
    procedure AsyncQuery(Addr: string; QueryType: TServerType; ResultProc: TStateProc);
    // �첽ʽ��ѯȫ�ַ�����������ResultProc��һ���ԣ�������һ��������С�ķ�����ֵ�����еķ��صĲ�ѯ�����ServerList��
    procedure Query(Addr: string; QueryType: TServerType; ResultProc: TManagerQueryProc);

    procedure Disconnect;
    function ExistsServerType(ServerType: TServerType): Boolean;
    procedure Clear;

    procedure Progress;
  end;

implementation

procedure TQueryResultInfo.Init;
begin
  RegName := '';
  Host := '';
  RecvPort := 0;
  SendPort := 0;
  WorkLoad := -1;
  ServerType := TServerType.stUnknow;
end;

constructor TManagerQuery.Create(AClientIntf: TCommunicationFrameworkClient);
begin
  inherited Create;
  ClientIntf := AClientIntf;
  ServerList := TGenericsList<TQueryResultInfo>.Create;
end;

destructor TManagerQuery.Destroy;
begin
  DisposeObject(ServerList);
  inherited Destroy;
end;

procedure TManagerQuery.Progress;
begin
  ClientIntf.ProgressBackground;
end;

procedure TManagerQuery.Connect(Addr: string; Port: WORD);
begin
  ClientIntf.Connect(Addr, Port);
end;

procedure TManagerQuery.WaitQuery(Addr: string; QueryType: TServerType);
var
  sendDE, ResultDE: TDataFrameEngine;
  vl: THashVariantList;
  a: TQueryResultInfo;
begin
  ServerList.Clear;
  try
    Connect(Addr, CDEFAULT_MANAGERSERVICE_QUERYPORT);
    if (ClientIntf.Connected) and (ClientIntf.RemoteInited) then
      begin
        // ��ѯ�����ڹ�������ע��ķ��������������з�����
        sendDE := TDataFrameEngine.Create;
        sendDE.WriteByte(Byte(QueryType));

        ResultDE := TDataFrameEngine.Create;
        ClientIntf.WaitSendStreamCmd('Query', sendDE, ResultDE, 5000);

        vl := THashVariantList.Create;

        if ResultDE.Count > 0 then
          begin
            while not ResultDE.Reader.IsEnd do
              begin
                ResultDE.Reader.ReadVariantList(vl);
                a.RegName := vl.GetDefaultValue('Name', '');
                a.Host := vl.GetDefaultValue('Host', '');
                a.RecvPort := vl.GetDefaultValue('RecvPort', 0);
                a.SendPort := vl.GetDefaultValue('SendPort', 0);
                a.WorkLoad := vl.GetDefaultValue('WorkLoad', 0);
                a.ServerType := vl.GetDefaultValue('Type', TServerType.stUnknow);
                ServerList.Add(a);
                vl.Clear;
              end;
          end;

        DisposeObject(vl);

        DisposeObject(sendDE);
        DisposeObject(ResultDE);
      end;
  except
  end;
end;

procedure TManagerQuery.AsyncQuery(Addr: string; QueryType: TServerType; ResultProc: TStateProc);
var
  sendDE: TDataFrameEngine;
begin
  ServerList.Clear;
  try
    Connect(Addr, CDEFAULT_MANAGERSERVICE_QUERYPORT);
    if (ClientIntf.Connected) and (ClientIntf.RemoteInited) then
      begin
        // ��ѯ�����ڹ�������ע��ķ��������������з�����
        sendDE := TDataFrameEngine.Create;
        sendDE.WriteByte(Byte(QueryType));
        ClientIntf.SendStreamCmd('Query', sendDE, procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
          var
            vl: THashVariantList;
            a: TQueryResultInfo;
          begin
            vl := THashVariantList.Create;

            if ResultData.Count > 0 then
              begin
                while not ResultData.Reader.IsEnd do
                  begin
                    ResultData.Reader.ReadVariantList(vl);
                    a.RegName := vl.GetDefaultValue('Name', '');
                    a.Host := vl.GetDefaultValue('Host', '');
                    a.RecvPort := vl.GetDefaultValue('RecvPort', 0);
                    a.SendPort := vl.GetDefaultValue('SendPort', 0);
                    a.WorkLoad := vl.GetDefaultValue('WorkLoad', 0);
                    a.ServerType := vl.GetDefaultValue('Type', TServerType.stUnknow);
                    ServerList.Add(a);
                    vl.Clear;
                  end;
                ResultProc(True);
              end
            else
                ResultProc(False);

            DisposeObject(vl);
          end);

        DisposeObject(sendDE);
      end;
  except
  end;
end;

procedure TManagerQuery.Query(Addr: string; QueryType: TServerType; ResultProc: TManagerQueryProc);
var
  sendDE: TDataFrameEngine;
begin
  ServerList.Clear;
  try
    Connect(Addr, CDEFAULT_MANAGERSERVICE_QUERYPORT);
    if (ClientIntf.Connected) and (ClientIntf.RemoteInited) then
      begin
        // ��ѯ�����ڹ�������ע��ķ�������������С����
        sendDE := TDataFrameEngine.Create;
        sendDE.WriteByte(Byte(QueryType));
        ClientIntf.SendStreamCmd('QueryMinLoad', sendDE, procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
          var
            vl: THashVariantList;
            a: TQueryResultInfo;
          begin
            vl := THashVariantList.Create;

            if ResultData.Count > 0 then
              begin
                while not ResultData.Reader.IsEnd do
                  begin
                    ResultData.Reader.ReadVariantList(vl);
                    a.RegName := vl.GetDefaultValue('Name', '');
                    a.Host := vl.GetDefaultValue('Host', '');
                    a.RecvPort := vl.GetDefaultValue('RecvPort', 0);
                    a.SendPort := vl.GetDefaultValue('SendPort', 0);
                    a.WorkLoad := vl.GetDefaultValue('WorkLoad', 0);
                    a.ServerType := vl.GetDefaultValue('Type', TServerType.stUnknow);
                    if Assigned(ResultProc) then
                      begin
                        ResultProc(True, a);
                      end;
                    ServerList.Add(a);
                    vl.Clear;
                  end;
              end
            else
              begin
                a.Init;
                if Assigned(ResultProc) then
                    ResultProc(False, a);
              end;

            DisposeObject(vl);
          end);

        DisposeObject(sendDE);
      end;
  except
  end;
end;

procedure TManagerQuery.Disconnect;
begin
  try
      ClientIntf.ClientIO.Disconnect;
  except
  end;
end;

function TManagerQuery.ExistsServerType(ServerType: TServerType): Boolean;
var
  a: TQueryResultInfo;
begin
  Result := True;
  for a in ServerList do
    if a.ServerType = ServerType then
        exit;
  Result := False;
end;

procedure TManagerQuery.Clear;
begin
  ServerList.Clear;
end;

end.
