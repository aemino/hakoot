String ordinalSuffix(int n) {
  switch (n % 100) {
    case 11:
    case 12:
    case 13:
      return 'th';
  }

  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
  }

  return 'th';
}
