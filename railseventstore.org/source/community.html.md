---
title: Community
---

## Contributing to RailsEventStore organization repositories

Any kind of contribution is welcomed.

## Found a bug? Have a question?

* [Create a new issue](https://help.github.com/articles/creating-an-issue/), assuming one does not already exist.
* Clearly describe the problem including steps to reproduce when it is a bug.
* If possible provide a Pull Request with failing test case.

## Prepare a Pull Request

* Fork the [RailsEventStore monorepo](https://github.com/RailsEventStore/rails_event_store)

    ```
    git clone git@github.com:RailsEventStore/rails_event_store.git
    cd rails_event_store
    ```

* Make sure you have all latest changes or rebase your forked repository master branch with RailsEventStore master branch

    ```
    cd rails_event_store
    make rebase
    ```

* Create a pull request branch

    ```
    git checkout -b new_branch
    ```

* Implement your feature, don't forget about tests & documentation (to see how to work with documentation files check [documentation's readme ](https://github.com/RailsEventStore/rails_event_store/blob/master/railseventstore.org/README.md)

* Make sure your code pass all tests

    ```
    make test
    ```

    You could test each project separately, just enter the project folder and run tests (`make test` again) there.

* Make sure your changes survive mutation testing

    ```
    make mutate
    ```

    Will run mutation tests for all projects. The same command executed in specific project's folder will run mutation tests only for that project.
    Mutation tests might be time consuming, so you could try to limit the scope of mutations to some specific subjects:

    ```
    make mutate SUBJECT=code_to_mutate
    ```

    How to specify `code_to_mutate` is described in [Mutant documentation](https://github.com/mbj/mutant#test-selection).

* Don't forget to [create a Pull Request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/). You could do it even if not everything is ready. The sooner you will share your changes the quicker feedback you will get.

## License

By contributing, you agree that your contributions will be licensed under its [MIT License](https://github.com/RailsEventStore/rails_event_store/blob/master/LICENSE).
