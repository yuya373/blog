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
