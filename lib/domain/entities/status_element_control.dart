enum StatusElementControl { ok, ko;

  bool toJson() {
    switch (this) {
      case StatusElementControl.ok:
        return true;
      case StatusElementControl.ko:
        return false;
    }
  }
}