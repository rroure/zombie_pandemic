breed [persons person]
breed [trees tree]
persons-own [infected? immunized? health age gender]
patches-own [counter]

to setup
  clear-all
  setup-persons
  setup-patches
  setup-tree
  reset-ticks
end

to go
  ask persons [move]

  ; in order to consider pregnancy duration and time to "recover"
  if ticks mod 8 = 0  [ask persons with [infected? = False and gender = "female"][reproduce]]

  ; in order to consider pregnancy duration and time to "recover"
  ask patches [count-zombies destroy-safe-zone]

  ; criteria to stop the model
  if (count persons with [infected? = False] <= 0)
  or (count persons with [infected? = True] <= 0)
  or (count persons with [immunized? = False] <= 0) [stop]

  ; in order to create safe at a certain frequency (set to
  if ticks > 0 and ticks mod 20 = 0 [safe-zone]

  tick

end

to setup-patches
  ask patches [set pcolor white - 0.2 set counter 0]
end

to setup-tree
  create-trees 30 [
    setxy random-xcor random-ycor
    set size 1.5
    set shape "tree"
    set color green
  ]
end

to setup-persons
  create-persons Nhumans + Nzombies

  ask persons
  [ setxy random-xcor random-ycor

    set shape "person"
    set color green - 1.5
    set size 1

    set age random 91 ;; set an age between 0 and 90 yo
    set health random-normal 70 20
    ifelse random-float 1 < 0.5 [set gender "male"] [set gender "female"]

    set infected? False
    set immunized? False

  ]

  ask n-of (immun-prob * Nhumans) persons
     [
      set immunized? True
      set color blue

     ]

  ask n-of Nzombies persons
    [
    setxy random-xcor random-ycor
    set shape "ghost" set color red - 0.3 set size 1.1
    set infected? True
    set immunized? 0
    set health 0
    ]

end


;; procedure to make agents move associated to specific procedure
to move
  ;; for zombies
  ifelse infected?
   [ rt random 100 lt random 100 forward 0.08
    bit-humans]

  ;; for non infected persons
   [ ;; move and health depends on the patch - spend more time in safe zone gaining health
     ifelse pcolor = orange + 3
     [rt random 100 lt random 100 forward 0.04
      set health health + 2]
     [rt random 100 lt random 100 forward speed
      set health health - 5]; speed depends on age and health

    ;; physiological procedures
     eat
     get-older
     kill-zombie
     die-or-bezombie
   ]
end

;; create a safe zone (sanctuary) where non infected persons are protected
to safe-zone  ;
  let x-safe (min-pxcor + random (max-pxcor - min-pxcor - 2))
  let y-safe (min-pycor + random (max-pycor - min-pycor - 2))

  if all? patches [pcolor != orange + 3]
     [ask patches with [(pcolor != grey + 2) and
         x-safe < pxcor and pxcor < x-safe + 4 and
         y-safe < pycor and  pycor < y-safe + 4]
            [set pcolor orange + 3]
     ]
end

;; attack of the sanctuary by zombies with ability to destroy it
;; when attacked by 2000 zombies and make it not buildable again
to count-zombies
  ask patches with [pcolor = orange + 3]
     [if count(persons-here with [infected? = True])> 0
          [set counter counter + 1]
        ;set plabel counter
      ]
end

to destroy-safe-zone
  if counter > 2000 [ask patches with [pcolor = orange + 3] [set pcolor grey + 2 set counter 0]]
end


;; procedure to make zombies attack non infected persons bitting them
to bit-humans
  if infected? = True and pcolor != orange + 3
  [ask other persons-here with [infected? = False] ;ask (persons-on neighbors) with [infected? = False]
      [if  (random-float 1.01) < (age-factor) and (random-float 100) < (health)
        [ifelse immunized? = False
          ;; non immunized persons biten by a zombies will become a zombie
          [set shape "ghost"
           set color red - 0.3
           set infected? True
           set health 0 ]
          ;; immunized persons are injured losing health
          [set health health - 30]]
      ]
    ]
end

;; procedure to make non infected able to kill zombies
to kill-zombie ;; zombies can be defeated and killed or leave quiet
     ask other persons-here with [(infected? = True)] ;ask (persons-on neighbors4) with [(infected? = True)]
       [if (random-float 1 < survival-prob); speed)
          [die]
       ]
end


;; physiological procedure for non infected persons
to get-older ;1 tick == 1 quarter => each 4 ticks age increase by 1
  set age (age + 0.25)
end

to eat ;; humans health by eating but health can't exceed 100
  ifelse health > 100
   [set health 100]
   [ifelse pcolor != orange + 3
    [if (random-float 1 < food-prob) [set health health + energy-from-food]]
    [if (random-float 1 < food-prob + 0.5) [set health health + (energy-from-food + 5)]]] ; in a safe zone you have mroe chance to get food (of higher quality)
end

to reproduce
  if count persons < 1000 and (random-float 1) < 0.4 and (16 <= age) and (age <= 45) and health > 60
      [set health (health / 2)
          hatch 1 [set age 1
                   set health 60
                   rt random-float 360 fd speed
                   ifelse random-float 1 < 0.5  [set gender "male"]  [set gender "female"]
        ]]
end

;; if non immunized a person can either die or become a zombie (because having a sleeping virus)
to die-or-bezombie
  if (health <= 0 or age > 90)
     [ifelse immunized? = True
        [die]
        [ifelse (random-float 1 < 0.5) ;and other persons-here with [infected? = False]
           [die]
           [set shape "ghost"
            set color red - 0.3
            set infected? True
            set health 0]
        ]]
end


;; specific reporters for tracking
to-report speed ;; speed depends on health and age
  report sqrt ((health / 500 * age)^ 2)
end

to-report age-factor ;; age-related variable "following" a  upside down U shape parabola (assuming max is at 45 yo)
  report (0.04444444 * age - 0.000493827 * age * age)
end

to-report zombies
  report persons with [infected? = True]
end

to-report immune
  report persons with [immunized? = True]
end

to-report humans
  report persons with [infected? = False and immunized? = False]
end
@#$#@#$#@
GRAPHICS-WINDOW
222
11
679
469
-1
-1
13.61
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
22
46
85
79
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
129
46
192
79
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
20
107
192
140
Nhumans
Nhumans
0
400
200.0
1
1
NIL
HORIZONTAL

SLIDER
20
157
192
190
Nzombies
Nzombies
1
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
21
206
193
239
immun-prob
immun-prob
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
21
254
193
287
survival-prob
survival-prob
0
1
0.25
0.05
1
NIL
HORIZONTAL

PLOT
20
479
487
764
populations
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"zombies" 1.0 0 -5298144 true "" "plot count persons with [infected? = True]"
"immunized" 1.0 0 -14070903 true "" "plot count persons with [immunized? = True]"
"humans" 1.0 0 -14439633 true "" "plot count persons with [infected? = False]"

MONITOR
503
717
585
762
Time (years)
ticks / 4
17
1
11

MONITOR
498
480
582
525
Humans
count humans + count immune
17
1
11

MONITOR
596
480
680
525
Immunized
count immune
17
1
11

MONITOR
730
481
813
526
Zombies
count zombies
17
1
11

SLIDER
20
298
192
331
food-prob
food-prob
0
1
0.35
0.01
1
NIL
HORIZONTAL

SLIDER
21
347
193
380
energy-from-food
energy-from-food
0
50
17.0
1
1
NIL
HORIZONTAL

MONITOR
563
532
620
577
Female
count persons with [infected? = False and gender = \"female\"]
0
1
11

MONITOR
564
585
621
630
Male
count persons with [infected? = False and gender = \"male\"]
17
1
11

MONITOR
500
636
611
681
Human variation (%)
100 * (count humans + count immune - Nhumans) / Nhumans
17
1
11

MONITOR
716
636
833
681
Zombie variation (%)
100 * (count zombies - Nzombies) / Nzombies
17
1
11

MONITOR
619
636
710
681
% of immunized
100 * (count immune / count persons with [infected? = False])
2
1
11

@#$#@#$#@
## WHAT IS IT?

The model explores a post-apocalyptic world following the emergence of zombies due to a virus and the ability of humans to survive.

## HOW IT WORKS

Only 1 agent exists under 3 different states: healthy humans split into 2 sub-groups (immunized [blue] vs not immunized [green]) and zombies (infected [red]).

Agent "tree" is created for aesthetic purpose.

The model is initialized with 200 people, of which 10% are immunized and 1 zombie (infected).

Healthy non immunized people may turn zombie into 2 ways: either by death or bitten by a zombie. Indeed, they have a sleeping version of the virus that become active once they die transforming them in zombie. Please note that if they naturally die, they can avoid to be transformed in zombies being killed by other humans.

Immunized can't become zombie. They can only naturally die or loss health when attacked by zombie.

Person and zombies move randomly at different speeds according to their state and/or the patch where they are (see below).

### The density of the population

You can change the size of the initial population through the NHUMANS slider and NZOMBIES slider. In addition, the initial immune rate among humans (non-infected person) can be modified through the IMMUN-PROB slider.

### Population turnover

In this model, people naturally die at the age of 90 years or when their health level is less than 0. Non-immunized person can either “really” die or turn in zombies since they have sleeping version of the virus or earlier.

They can become zombie earlier if they are bitten by a zombie. A survival rate can be set through the SURVIVAL-PROB slider. That rate is used when a person non-infected is attacked by a zombie.

Reproduction rate is random (< 0.4) and linked to the gender, age and health (only female aged between 16 and 45 with health > 60 can reproduce). We set a reproduction turnover at 8 ticks to mimic pregnancy and post-partum recovery (8 ticks = 24 months).

Population capacity of the world is set to 1000.

### Health (non-infected population)

Non-infected population initially gets a health level randomly (normally distributed around 70 with a std of 20). They spend health by moving and being attacked by zombie (and for reproduction too).

They can gain health (energy) through food. They randomly find food based on the value set through slider FOOD-PROB. The level of health obtained from food can be set through ENERGY-FROM-FOOD slider.

### Move

Zombies moved more slowly than healthy population.

Healthy population move at a speed “related” to their age. We try to mimic the fact that older people move less quickly than younger. Speed is also different depending on the patch characteritics (see "Things to notice").

## HOW TO USE IT

Each “tick” represents a quarter (3 months) in the time scale of this model (meaning 1 year = 4 ticks).

The SETUP button resets the graphics and plots and randomly distributes NHUMANS and NZOMBIES in the view. All but 20 of the people are set to be blue immunized people and 1 red zombie (infected). Humans are of randomly distributed ages and gender. The GO button starts the simulation and the plotting function.

The SURVIVAL-PROB slider determines how great the chance is that human will defeat (kill) zombie when they are attacked. For instance, when the slider is set to 0.25, they can kill a zombie once every 4 chances.

The FOOD-PROB slider determines the chance to find food in order to gain health. The ENERGY-FROM-FOOD slider set the unit of health gained when humans find food.

Eight output monitors show:
* the total number of humans, its variation compared to initial population and the number of female and male
* the number of immune people and its percentage (among humans) in order to see how immunization is spreading
* the number of zombie, its variation compared to initial zombie population. 
Finally, an output window display the time in years since the beginning.

The plot shows (in their respective colors) the total number of humans (green), immunized population (blue) and zombies (red)

## THINGS TO NOTICE

### Safe zone
A safe zone (orange patches) randomly appears offering a zone where non-infected people can be “protected” from zombie. In that zone, they move less slowly to mimic a long stay and they gain health.
That zone can be attacked by zombies and destroyed when more than 2000 zombies passed through 1 patch of the zone (the patches turn grey and can’t become orange anymore).

## THINGS TO TRY

* Increase the initial size of zombies population
* Increase the size of human population
* Increase the immune rate among human
* Play with the survival probability
* Play with the probability of finding food (could be higher in safe zone) and/or energy-from-food

## EXTENDING THE MODEL

There are many ways to improve the model:

* make zombies move in hord (like in flocking model)
* introduce a vaccine to boost immune population
* play with patches (can they provide food?)
* safe zone: limit the population density / make human attracted by that zone
* fine tune the ability of kill zombie (based on age, health, experience, weapon acquisition/development)
* improve speed parameter (to be linked to health and better linked to age)
* make trees consider as obstacle

## RELATED MODELS

Inspired by Virus models

## CREDITS AND REFERENCES

Model mainly inspired from The Walking Dead comics and TV show (and others theory around zombies)

NOTE: I am not OK to share my work with future students or anyone else.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghost
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count humans</metric>
    <metric>count immune</metric>
    <metric>count zombies</metric>
    <enumeratedValueSet variable="survival-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-food">
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-prob">
      <value value="0.5"/>
      <value value="0.4"/>
      <value value="0.3"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.3"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immun-prob">
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nhumans">
      <value value="150"/>
      <value value="200"/>
      <value value="300"/>
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nzombies">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
