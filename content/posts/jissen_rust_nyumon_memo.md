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

