using System;
using Pollen.Localization;

namespace Pollen.ViewModels;

public class MainViewModel : ViewModelBase
{
    public IObservable<string?> Greeting => LocalizationService.Welcome;
}
