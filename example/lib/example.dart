import 'package:collection/collection.dart';

class Person {
  final String? name;
  final double? height;
  final int age;
  final String? nickname;
  final List<List<Animal>> pets;

  Person(
    this.height, {
    this.name,
    required this.age,
    this.nickname,
    required this.pets,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          name == other.name &&
          height == other.height &&
          age == other.age &&
          nickname == other.nickname &&
          const DeepCollectionEquality().equals(pets, other.pets);

  @override
  int get hashCode => Object.hash(
    name,
    height,
    age,
    nickname,
    const DeepCollectionEquality().hash(pets),
  );

  Person copyWith({
    ({String? value})? name,
    ({double? value})? height,
    ({int value})? age,
    ({String? value})? nickname,
    ({List<List<Animal>> value})? pets,
  }) {
    return Person(
      height == null ? this.height : height.value,
      name: name == null ? this.name : name.value,
      age: age == null ? this.age : age.value,
      nickname: nickname == null ? this.nickname : nickname.value,
      pets: pets == null ? this.pets : pets.value,
    );
  }

  @override
  String toString() {
    return 'Person{name: $name, height: $height, age: $age, nickname: $nickname, pets: $pets}';
  }
}

class Animal {
  final String species;
  final String? name;
  final int age;

  Animal(this.species, {this.name, required this.age});

  @override
  String toString() {
    return 'Animal{species: $species, name: $name, age: $age}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Animal &&
          species == other.species &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => Object.hash(species, name, age);

  Animal copyWith({
    ({String value})? species,
    ({String? value})? name,
    ({int value})? age,
  }) {
    return Animal(
      species == null ? this.species : species.value,
      name: name == null ? this.name : name.value,
      age: age == null ? this.age : age.value,
    );
  }
}

void main() {
  final person1 = Person(
    5.9,
    name: 'Alice',
    age: 30,
    nickname: 'Ally',
    pets: [
      [
        Animal('Dog', name: 'Buddy', age: 5),
        Animal('Cat', name: 'Whiskers', age: 3),
      ],
      [Animal('Parrot', name: 'Polly', age: 2)],
    ],
  );
  final person2 = person1.copyWith(name: (value: 'Bob'), age: (value: 31));
  final person3 = person2.copyWith(name: (value: null));
  final copyOfPerson3 = person3.copyWith();

  print(person1);
  // Output: Person{name: Alice, height: 5.9, age: 30, nickname: Ally, pets: [[Animal{species: Dog, name: Buddy, age: 5}, Animal{species: Cat, name: Whiskers, age: 3}], [Animal{species: Parrot, name: Polly, age: 2}]]}
  print(person2);
  // Output: Person{name: Bob, height: 5.9, age: 31, nickname: Ally, pets: [[Animal{species: Dog, name: Buddy, age: 5}, Animal{species: Cat, name: Whiskers, age: 3}], [Animal{species: Parrot, name: Polly, age: 2}]]}
  print(person1 == person2);
  // Output: false
  print(person3);
  // Output: Person{name: null, height: 5.9, age: 31, nickname: Ally, pets: [[Animal{species: Dog, name: Buddy, age: 5}, Animal{species: Cat, name: Whiskers, age: 3}], [Animal{species: Parrot, name: Polly, age: 2}]]}
  print(copyOfPerson3);
  // Output: Person{name: null, height: 5.9, age: 31, nickname: Ally, pets: [[Animal{species: Dog, name: Buddy, age: 5}, Animal{species: Cat, name: Whiskers, age: 3}], [Animal{species: Parrot, name: Polly, age: 2}]]}
  print(person3 == copyOfPerson3);
  // Output: true
}
