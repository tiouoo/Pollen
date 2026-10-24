using OvoUi.Tab;
using Pollen.ViewModels;

namespace Pollen.Views;

public partial class MainWindow : OvoTabWindow
{
    public MainWindow()
        : this(new OvoTabService(), isPrimaryWindow: true)
    {
        AddTab(CreateTab());
    }

    private MainWindow(OvoTabService tabService, bool isPrimaryWindow)
        : base(tabService)
    {
        InitializeComponent();
        IsPrimaryWindow = isPrimaryWindow;
        UseSelectedTabTitle = false;
        NewTabFactory = CreateTab;

        tabService.WindowFactory = context => new MainWindow(context.Service, isPrimaryWindow: false);
    }

    private static OvoTabItem CreateTab() => new("Pollen", new MainView
    {
        DataContext = new MainViewModel()
    });
}
