
# Endogenous Macrodynamics in Algorithmic Recourse

This repository contains all code, notebooks, data and empirical results
for our conference paper “Endogenous Macrodynamics in Algorithmic
Recourse”.

## Motivation

The chart below illustrates what we define as macrodynamics in
Algorithmic Recourse: (a) we have a simple linear classifier trained for
binary classification where samples from the negative class ($y=0$) are
marked in blue and samples of the positive class ($y=1$) are marked in
orange; (b) the implementation of AR for a random subset of individuals
leads to a noticable domain shift; (c) as the classifier is retrained we
observe a corresponding model shift; (d) as this process is repeated,
the decision boundary moves away from the target class.

![](cover.png)

## Abstract

Existing work on Counterfactual Explanations (CE) and Algorithmic
Recourse (AR) has largely focused on single individuals in a static
environment: given some estimated model, the goal is to find valid
counterfactuals for an individual instance that fulfill various
desiderata. The ability of such counterfactuals to handle dynamics like
data and model drift remains a largely unexplored research challenge.
There has also been surprisingly little work on the related question of
how the actual implementation of recourse by one individual may affect
other individuals. Through this work we aim to close that gap. We first
show that many of the existing methodologies can be collectively
described by a generalized framework. We then argue that the existing
framework does not account for a hidden external cost of recourse, that
only reveals itself when studying the endogenous dynamics of recourse at
the group level. Through simulation experiments involving various
state-of-the-art counterfactual generators and several benchmark
datasets, we generate large numbers of counterfactuals and study the
resulting domain and model shifts. We find that the induced shifts are
substantial enough to likely impede the applicability of Algorithmic
Recourse in some situations. Fortunately, we find various strategies to
mitigate these concerns. Our simulation framework for studying recourse
dynamics is fast and open-sourced.