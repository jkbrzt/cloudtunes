module.exports =

    escapeRegExp: (re)->
        re.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

    timed: (name, func)->
        ->
            console.time name
            res = func Array::slice arguments
            console.timeEnd name
            res
