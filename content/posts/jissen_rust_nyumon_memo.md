---
title: "実践Rust入門のメモ"
date: 2019-05-02T17:00:00+09:00
draft: false
isCJKLanguage: true
tags: ["Rust", "reading notes"]
---

## 3-5-4　クロージャの型について
### Rustのクロージャの型は全て違う

> なぜならクロージャの型は個々のクロージャで異なり、2つとして同じ型がないからです。これはクロージャが自分専用の環境を持つことができるからです。

``` rust
fn bad<F>(f1: &F, f2: &F) {}

fn main() {
    bad(&|| {}, &|| {})
}
```

```
mismatched types (expected closure, found a different closure) [E0308]
...snip...
no two closures, even if identical, have the same type [E0308]
consider boxing your closure and/or using it as a trait object [E0308]
```

> 正しく定義するにはそれぞれのクロージャに別々の型パラメータを与えます。

``` rust
fn good<F1, F2>(f1: &F1, f2: &F1) {}

fn main() {
    good(&|| {}, &|| {})
}
```

## 3-6-4　SyncトレイトとSendトレイト

### `rayon::join`の型

``` rust
pub fn join<A, B, RA, RB>(oper_a: A, oper_b: B) -> (RA, RB) where A: FnOnce() -> RA + Send, B: FnOnce() -> RB + Send, RA: Send, RB: Send
```
### FnOnce
https://doc.rust-lang.org/std/ops/trait.FnOnce.html

> Instances of FnOnce can be called, but might not be callable multiple times. Because of this, if the only thing known about a type is that it implements FnOnce, it can only be called once.

> Use FnOnce as a bound when you want to accept a parameter of function-like type and only need to call it once. If you need to call the parameter repeatedly, use FnMut as a bound; if you also need it to not mutate state, use Fn.

### Send, Sync
#### https://doc.rust-lang.org/book/ch16-04-extensible-concurrency-sync-and-send.html

> The Sync marker trait indicates that it is safe for the type implementing Sync to be referenced from multiple threads. In other words, any type T is Sync if &T (a reference to T) is Send, meaning the reference can be sent safely to another thread

#### https://doc.rust-lang.org/nomicon/send-and-sync.html

#### https://doc.rust-lang.org/std/marker/trait.Send.html

> Types that can be transferred across thread boundaries.

> This trait is automatically implemented when the compiler determines it's appropriate.

#### https://doc.rust-lang.org/std/marker/trait.Sync.html

> Types for which it is safe to share references between threads.

> This trait is automatically implemented when the compiler determines it's appropriate.

> The precise definition is: a type T is Sync if and only if &T is Send. In other words, if there is no possibility of undefined behavior (including data races) when passing &T references between threads.

## 4-2-3　固定精度の整数

### アドレス幅の整数型
- [rust - What's the difference between `usize` and `u32`? - Stack Overflow](https://stackoverflow.com/questions/29592256/whats-the-difference-between-usize-and-u32)
- [Beginner question: Should I use usize and isize for my numbers? : rust](https://www.reddit.com/r/rust/comments/4lql5l/beginner_question_should_i_use_usize_and_isize/)
- [usize - Rust](https://doc.rust-lang.org/std/primitive.usize.html)
- [isize - Rust](https://doc.rust-lang.org/std/primitive.isize.html)

`usize`, `isize`はメモリアドレスの幅(32bit, 64bit)によってサイズが変わる。
メモリアドレスを指し示す場合に使う
u32では64bit環境の場合足りない場合があり、u64なら32bit環境の場合あふれてしまう？

## 4-2-8　関数ポインタ

``` rust
    fn double(n: i32) -> i32 {
        n + n
    }

    let mut f: fn(i32) -> i32 = double;
```

`f`に型注釈が必要。型注釈がないと関数定義型と推論される

### 関数定義型
関数定義型は関数によって異なる。

``` rust
    let mut f_bad = double;
    f_bad = abs;
```

```
    error[E0308]: mismatched types
       --> src/main.rs:103:13
        |
    103 |     f_bad = abs;
        |             ^^^ expected fn item, found a different fn item
        |
        = note: expected type `fn(i32) -> i32 {main::double}`
                   found type `fn(i32) -> i32 {main::abs}`
```

関数定義型の値のサイズは0バイト

``` rust
    assert_eq!(std::mem::size_of_val(&f_bad), 0);
```

### クロージャの型
クロージャを定義する毎に専用の匿名型が作られる。

``` rust
    let b = 5;
    let mut f = |a| a * 3 + b;
    f = |a| a * 4 + b;
```

```
error[E0308]: mismatched types
   --> src/main.rs:133:9
    |
133 |     f = |a| a * 4 + b;
    |         ^^^^^^^^^^^^^ expected closure, found a different closure
    |
    = note: expected type `[closure@src/main.rs:132:17: 132:30 b:_]`
               found type `[closure@src/main.rs:133:9: 133:22 b:_]`
    = note: no two closures, even if identical, have the same type
    = help: consider boxing your closure and/or using it as a trait object
```

クロージャは関数ポインタ型にもなれる

``` rust
    let mut f: fn(i32) -> i32 = |n| n * 3;
    assert_eq!(f(-42), -126);
```

環境になにかを補足しているクロージャは関数ポインタ型にはなれない。

``` rust
    let x = 4;
    f = |n| n * x;
```

```
error[E0308]: mismatched types
   --> src/main.rs:135:9
    |
135 |     f = |n| n * x;
    |         ^^^^^^^^^ expected fn pointer, found closure
    |
    = note: expected type `fn(i32) -> i32`
               found type `[closure@src/main.rs:135:9: 135:18 x:_]`
```

## 4-3-3　スライス

> スライス型（slice type）は配列要素の範囲に効率よくアクセスするためのビューです。配列といってもスライスが対象とするデータ構造は配列だけではありません。連続したメモリ領域に同じ型の要素が並んでいるデータ構造なら、どれでも対象にできます。このようなデータ型にはベクタや、Rust以外の言語で作成した配列なども含まれます。

### ボックス化されたスライス

> &[T]や&mut[T]といった一般的なスライスはポインタの一種で、それ自身はデータの実体は持ちません。代わりに配列といった別の場所で作られたデータ構造を参照します。 これをRustの所有権システムの用語では「データを所有せず、借用している」といいます。スライスのライフタイムが尽きてメモリから削除されても、それが借用していた実データはそのままメモリに残ります。

> 一方、Box<[T]>はデータを所有します。実データはヒープと呼ばれるメモリ領域に格納され、このスライスのライフタイムが尽きると実データがメモリから削除されます。

## 5-2-1　Box（std::boxed::Box<T>）
- [Using Box<T> to Point to Data on the Heap - The Rust Programming Language](https://doc.rust-lang.org/book/ch15-01-box.html)
- [std::boxed - Rust](https://doc.rust-lang.org/std/boxed/index.html)

### moveでも大きな構造体はコストがかかる
- [Rustの配置構文とbox構文 - 簡潔なQ](https://qnighy.hatenablog.com/entry/2017/06/06/220000)


### 再帰的なデータ構造はコンパイル時にデータサイズが決まらないので`Box`が必要

``` rust
    enum List<T> {
        Nil,
        Cons(T, List<T>),
    }
```

```
error[E0072]: recursive type `main::List` has infinite size
  --> src/main.rs:13:5
   |
13 |     enum List<T> {
   |     ^^^^^^^^^^^^ recursive type has infinite size
14 |         Nil,
15 |         Cons(T, List<T>),
   |                 ------- recursive without indirection
   |
   = help: insert indirection (e.g., a `Box`, `Rc`, or `&`) at some point to make `main::List` representable
```

``` rust
    enum List<T> {
        Nil,
        Cons(T, Box<List<T>>),
    }
```

### `Box`のサイズは一定
- [Why is Box able to have a defined size when simply defined recursive type don't have a defined size? : rust](https://www.reddit.com/r/rust/comments/72f3az/why_is_box_able_to_have_a_defined_size_when/)

``` rust
    println!("Size: {}", std::mem::size_of::<()>());
    println!("Size: {}", std::mem::size_of::<Box<()>>());
    println!("Size: {}", std::mem::size_of::<char>());
    println!("Size: {}", std::mem::size_of::<Box<char>>());
    println!("Size: {}", std::mem::size_of::<u32>());
    println!("Size: {}", std::mem::size_of::<Box<u32>>());
    println!("Size: {}", std::mem::size_of::<Vec<String>>());
    println!("Size: {}", std::mem::size_of::<Box<Vec<String>>>());
```

```
Size: 0
Size: 8
Size: 4
Size: 8
Size: 4
Size: 8
Size: 24
Size: 8
```
- [Rustでゼロサイズのヒープ領域を確保した時の挙動 - Qiita](https://qiita.com/garkimasera/items/6d36b1e6b566ce396a4a)

## 5-2-2　ベクタ（std::vec::Vec<T>）

> また事前に大まかな要素数が分かっているときはwith_capacity(要素数)メソッドを使うといいでしょう。ベクタに要素を追加していく際のメモリ再割り当てのオーバヘッドが削減できますので、大量の要素を追加するときはnew()よりも実行時間が短くなることが期待できます。

``` rust
    let mut v: Vec<char> = Vec::with_capacity(1000);
    println!("length: {}, capacity: {}", v.len(), v.capacity());
    v.shrink_to_fit();
    println!("length: {}, capacity: {}", v.len(), v.capacity());
```

```
length: 0, capacity: 1000
length: 0, capacity: 0
```

|               | 実データを格納するメモリ領域   | 実データを所有 | 要素の追加 |
|:-------------:|:------------------------------:|:--------------:|:----------:|
| `Vec<T>`      | ヒープ                         | する           | ○         |
| `[T; n]`      | スタック                       | する           | ×         |
| `Box<[T]>`    | ヒープ                         | する           | ×         |
| `&[T]`, `[T]` | ヒープorスタック、参照先に依存 | しない         | ×         |


- ベクタは要素数の増加に備えて余分なスペースをヒープ領域に確保する
- `Box<[T]>`は余分なスペースを持たない

``` rust
    let mut v1 = vec![0, 1, 2, 3];
    v1.push(4);
    println!("v1 len: {}, capacity: {}", v1.len(), v1.capacity());
    let s1 = v1.into_boxed_slice();
    let v2 = s1.into_vec();
    println!("v2 len: {}, capacity: {}", v2.len(), v2.capacity());
```

```
v1 len: 5, capacity: 8
v2 len: 5, capacity: 5
```

## 5-2-7　リザルト（std::result::Result<T, E>）

> 独自のエラー型を定義する際は、std::convert::Fromという型変換用のトレイトを実装するのがお勧めです。こうすると?演算子が関数の戻り値の型に合うようにエラーを変換してくれます。つまり、いちいちmap_err()で変換する必要がなくなります。

### [std::convert::From - Rust](https://doc.rust-lang.org/std/convert/trait.From.html)

``` rust
    enum MyError {
        ParseError(std::num::ParseIntError),
    }

    fn f() -> Result<(), MyError> {
        "abc".parse::<i32>()?;
        Ok(())
    }
```

```
error[E0277]: `?` couldn't convert the error to `main::MyError`
   --> src/main.rs:218:29
    |
218 |         "abc".parse::<i32>()?;
    |                             ^ the trait `std::convert::From<std::num::ParseIntError>` is not implemented for `main::MyError`
    |
    = note: required by `std::convert::From::from`
```

``` rust
    enum MyError {
        ParseError(std::num::ParseIntError),
    }

    fn f() -> Result<(), MyError> {
        "abc".parse::<i32>()?;
        Ok(())
    }

    impl std::convert::From<std::num::ParseIntError> for MyError {
        fn from(source: std::num::ParseIntError) -> Self {
            MyError::ParseError(source)
        }
    }
```

## 5-3-2　構造体（struct）
### デフォルト値の設定

``` rust
 #[derive(Default)]
 struct Polygon {
     vertexes: Vec<(i32, i32)>,
     stroke_width: u8,
     fill: (u8, u8, u8),
 }
```

``` rust
    struct Polygon {
        vertexes: Vec<(i32, i32)>,
        stroke_width: u8,
        fill: (u8, u8, u8),
    }

    impl Default for Polygon {
        fn default() -> Self {
            Self {
                stroke_width: 1,
                vertexes: Default::default(),
                fill: Default::default(),
            }
        }
    }

    let p: Polygon = Default::default();
    assert_eq!(p.stroke_width, 1);
```


### タプル構造体

> タプル構造体の便利な使い方の1つにnewtype＊6と呼ばれるRust特有のデザインパターンがあります。これは型エイリアスの代わりにフィールドが1つのタプル構造体を定義することで、コンパイラの型チェックを強化するテクニックです。

``` rust
    type UserName = String;
    type Id = i64;
    type Timestamp = i64;
    type User = (Id, UserName, Timestamp);

    fn new_user(name: UserName, id: Id, created: Timestamp) -> User {
        (id, name, created)
    }

    let id = 400;
    let now = 4567890123;
    let user = new_user(String::from("mika"), id, now);

    // no compile error
    let bad_user = new_user(String::from("bad user"), now, id);
```

``` rust
        struct UserName(String);
        struct Id(u64);
        struct Timestamp(u64);

        type User = (Id, UserName, Timestamp);

        fn new_user(name: UserName, id: Id, created: Timestamp) -> User {
            (id, name, created)
        }

        let id = Id(400);
        let now = Timestamp(4567890123);
        let bad_user = new_user(UserName(String::from("bad user")), now, id);
```

```
error[E0308]: mismatched types
   --> src/main.rs:339:69
    |
339 |         let bad_user = new_user(UserName(String::from("bad user")), now, id);
    |                                                                     ^^^ expected struct `main::Id`, found struct `main::Timestamp`
    |
    = note: expected type `main::Id`
               found type `main::Timestamp`

error[E0308]: mismatched types
   --> src/main.rs:339:74
    |
339 |         let bad_user = new_user(UserName(String::from("bad user")), now, id);
    |                                                                          ^^ expected struct `main::Timestamp`, found struct `main::Id`
    |
    = note: expected type `main::Timestamp`
               found type `main::Id`
```

> フィールドが1つのタプル構造体はゼロコスト抽象化の対象になり、そのメモリ上の表現は包んでいる型の表現と基本的に同じになります。たとえば上のId(400)のメモリ上のサイズは、u64型の400のメモリ上のサイズと同じ8バイトになるはずです。ただしコンパイラはデフォルトではメモリ上の表現が同一であることを保証しません。それを保証するためには構造体の定義に#[repr(transparent)]アトリビュートを付けます＊7。
