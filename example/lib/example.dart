class Person {
  final String? name;
  final double? height;
  final int age;
  final String? nickname;

  Person(this.height, {this.name, required this.age, this.nickname});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          name == other.name &&
          height == other.height &&
          age == other.age &&
          nickname == other.nickname;

  @override
  int get hashCode => Object.hashAll([name, height, age, nickname]);

  @override
  String toString() {
    return 'Person{name: $name, height: $height, age: $age, nickname: $nickname}';
  }

  Person copyWith({
    ({String? value})? name,
    ({double? value})? height,
    ({int value})? age,
    ({String? value})? nickname,
  }) {
    return Person(
      height == null ? this.height : height.value,
      name: name == null ? this.name : name.value,
      age: age == null ? this.age : age.value,
      nickname: nickname == null ? this.nickname : nickname.value,
    );
  }
}

class Animal {
  final String species;
  final String? name;
  final int age;

  Animal(this.species, {this.name, required this.age});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Animal &&
          species == other.species &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hashAll([species, name, age]);

  @override
  String toString() {
    return 'Animal{species: $species, name: $name, age: $age}';
  }
}

void main() {
  final person1 = Person(5.9, name: 'Alice', age: 30, nickname: 'Ally');
  final person2 = person1.copyWith(name: (value: 'Bob'), age: (value: 31));
  final person3 = person2.copyWith(name: (value: null));
  final copyOfPerson3 = person3.copyWith();

  print(person1);
  // Output: Person{name: Alice, height: 5.9, age: 30, nickname: Ally}
  print(person2);
  // Output: Person{name: Bob, height: 5.9, age: 31, nickname: Ally}
  print(person1 == person2);
  // Output: false
  print(person3);
  // Output: Person{name: null, height: 5.9, age: 31, nickname: Ally}
  print(copyOfPerson3);
  // Output: Person{name: null, height: 5.9, age: 31, nickname: Ally}
  print(person3 == copyOfPerson3);
  // Output: true
}
