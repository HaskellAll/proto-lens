# Person Example

In this section we will go through how to setup a package with a simple definition of a Person via a `.proto` file. Along the way we will look at what code is generated for our definition and provide explanations of some of the features.

## Table of Contents

1. [Tutorial](#tutorial-setting-up-a-basic-package)
  1. [Setup](#setup)
    1. [Create a New Project](#1-create-a-new-stack-project)
    2. [Setup Proto Package](#2-setup-proto)
    3. [Setup Person Package](#3-setup-person)
  2. [Troubleshooting](#troubleshooting)
  3. [Finding Autogenerated Files](#finding-autogenerated-files)
2. [What Do We Get?](#what-do-we-get)
  1. [Message and Lenses](#message-and-lenses)
  2. [Building a Message](#building-a-message)
3. [Did We Miss Something?](#did-we-miss-something)

## Tutorial: Setting Up a Basic Package
In this tutorial we are going to visit how to set up `proto-lens` and all its goodness. The result will match the contents of this git directory.

### Setup

I am going to use `stack` and `hpack` to set things up. So here we go:

#### 1. Create a New Stack Project

The command to follow will create a basic Haskell directory structure for a [stack](https://docs.haskellstack.org/en/stable/README/) project. It will use `hpack` which is a way of defining your project in a `.yaml` file which generates a `.cabal` file upon `stack build`. After this we `cd` into the directory created.

`stack --resolver nightly-2018-05-09 new person simple-hpack && cd person`

We'll make a single package in this example, so we can leave the autogenerated `stack.yaml` as-is.

#### 2. Generate Haskell sources from proto files
Now we have our top level project, we will start with creating a directory `proto` to contain all of our files, and a file `person.proto` inside that directory with the following contents:

``` protobuf
syntax="proto3";

message Person {
    string name = 1;
    int32 age = 2;

    // Address is a message defined below.
    repeated Address addresses = 3;
}

message Address {
  string street = 1;
  string zip_code = 2;
}
```

Next we will edit the `package.yaml` file to set up code generation:

``` yaml
name: person

custom-setup:
  dependencies:
    - base
    - Cabal
    - proto-lens-setup

extra-source-files: proto/**/*.proto

library:
  dependencies:
    - base
    - proto-lens-runtime

  exposed-modules:
    - Proto.Person
    - Proto.Person_Fields
```

This will autogenerate two modules `Proto.Person` where our records will be defined and `Proto.Person_Fields` where our field accessors will be defined.

The last thing we need to do here is edit `Setup.hs` to have:

``` haskell
import Data.ProtoLens.Setup

main = defaultMainGeneratingProtos "proto"
```

#### 3. Use the autogenerated modules in an executable

Alright! We are going to test this puppy out! We will make a file `src/Main.hs` so we can create and print some stuff out!

``` haskell
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Proto.Person as P
import Proto.Person_Fields as P
import Data.ProtoLens (defMessage, showMessage)
import Lens.Micro

person :: P.Person
person =
  defMessage
      & P.name      .~ "Fintan"
      & P.age       .~ 24
      & P.addresses .~ [address]
  where
    address :: P.Address
    address =
      defMessage
          & P.street  .~ "Yolo street"
          & P.zipCode .~ "D8"


main :: IO ()
main = do
  putStrLn . showMessage $ person
```

Then, we'll put it in an `executable` section to `package.yaml` that specifies its dependencies.  They include the library we created above (`person`) along with `microlens` and `proto-lens`

``` yaml
executables:
  person:
    main: Main.hs
    source-dirs: '.'
    dependencies:
      - base
      - person
      - microlens
      - proto-lens
```

### Troubleshooting

You may run into issues with not being able to find names and what not when trying to run `stack build`. If this is occurring then try do a `stack clean --full` and try `stack build` again.

### Finding Autogenerated Files

The autogenerated files will be located in your `proto` directories `.stack-work`. If you want to inspect any of the files you can open the files that are found by the command below.

To find the ones we create you can run:
`find proto -name Person`

## What Do We Get?

### Message and Lenses

When we build our protobuffers what is it we get? Code is autogenerated to give us two files `Person.hs` and `Person_Fields.hs` which contain our records and our field accessors respectively. This is roughly what they look like:

``` haskell
-- Person.hs

module Proto.Person where
-- imports

data Address = ...
  deriving (Prelude.Show, Prelude.Eq, Prelude.Ord)

instance Data.ProtoLens.Message Address where
  -- instance definition

instance Lens.Labels.HasLens' Address "street" Data.Text.Text where
-- instance definition

instance Lens.Labels.HasLens' Address "zipCode" Data.Text.Text where
-- instance definition


data Person = ...
  deriving (Prelude.Show, Prelude.Eq, Prelude.Ord)

-- same instances with different labels
```

``` haskell
-- Person_Fields.hs

module Proto.Person_Fields where
-- imports

addresses :: Lens.Labels.HasLens s "address" a => Lens' s a

age :: Lens.Labels.HasLens s "age" a => Lens' s a

name :: Lens.Labels.HasLens s "name" a => Lens' s a

street :: Lens.Labels.HasLens s "street" a => Lens' s a

zipCode :: Lens.Labels.HasLens s "zipCode" a => Lens' s a
```

So we have our data types for Person and Address and they have instances for:

* `Lens.Labels.HasLens'`
  * Allows us to use overloaded lenses for interacting with our data i.e. get/set.  

* Message
  * This class provides `defMessage :: Message a => a` constructing message with [default values](https://developers.google.com/protocol-buffers/docs/proto3#default)
  * This class also enables serialization (`encodeMessage` and `decodeMessage` from the `proto-lens` library) by providing reflection for all of the fields that may be used by this type.

### Building a Message

Using your favourite lens library we can create our proto data by doing the following:

``` haskell
import Proto.Person as P
import Proto.Person_Fields as P
import Data.ProtoLens (defMessage)

fintan :: P.Person                      -- Signal the compiler what we are creating a Person
fintan = defMessage
             & P.name      .~ "Fintan"  -- set the `name` of our person
             & P.age       .~ 24        -- set the `age` of our person
             & P.addresses .~ addresses -- set the `addresses` of our person
```

## Did We Miss Something?

If you noticed anything that is missing or wrong please file an issue or make a PR :)
