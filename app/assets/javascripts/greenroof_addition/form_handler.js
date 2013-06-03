$(document).ready(function () {

    init()
});

var plants = []

// initializes the button listeners for the form
function init() {
    $('#form').submit(function (event) {
        // cancels the form submission
        event.preventDefault();
    });
    var layerDropdownList = $('#add-layer-dropdown-list').children()
    layerDropdownList.each(function(index, value) {
        $(this).click(addLayer)
        console.log($(this))
    })
    $('#add-base-button').click(addBase)
    $('#save').click(save)
    $('#add-layer-button').click(function(e) {
        e.preventDefault()
    })

}

// listener function for the addition of a new base
var addBase = function addBase(event) {

    event.preventDefault()
    var formElement = $('#base-form')
    formElement.append(generateBaseForm())
}

function generateBaseForm() {

    // gets the number of direct div child elements of #base-form
    var baseCount = $('#base-form > div').size() + 1
    // adds the container for the form
    var baseFormElement = $('<div></div>').attr('id', 'base' + baseCount).attr('class', 'baseAdder')
    // adds the header
    var h2Element = $('<h2>Pohja ' + baseCount + '</h2>').attr('class', 'span4')
    baseFormElement.append(h2Element)
    // adds a button for removing the base
    var removeButton = $('<button>Poista pohja</button>').attr('class', "btn btn-mini btn-danger").click(removeParent)
    baseFormElement.append(removeButton)
    // clones the label from the first base form which was generated by the rails template and adds it in the new form
    var labelElement = $('#base-form div label').first().clone()
    baseFormElement.append(labelElement)
    // same done for the input
    var absorbancyInputElement = $('#base-form div input').first().clone().val("");
    baseFormElement.append(absorbancyInputElement)
    // adds a button for adding more layers for the base
    var addLayerButton = $('#base-form div button').first().clone().attr('id', 'add-layer-button-' + baseCount).click(addLayer)
    baseFormElement.append(addLayerButton)
    // creates an initial form for the layers and adds it
    //var layerElement = generateLayerForm(1)
    // baseFormElement.append(layerElement)
    // returns the created form element for a new base
    return baseFormElement
}

// function for removing the invoked element's paren (in this case the remove buttons parents)
var removeParent = function (event) {
    $(event.target).parent().remove()
}

// listener for the addition of a new layer form
var addLayer = function addLayer(event) {

    event.preventDefault()
    var baseFormElement = $(event.target).parent()
    //var layerCount = baseFormElement.children('div').size()
    var layerElement = generateLayerForm(event.target)
    layerElement.insertBefore('#add-layer-btn-grp')
}

function generateLayerForm(target) {
    console.log(target.text)
    // creates a new container for the layer form
    var layerFormElement = $('<div></div>').attr('class', 'layer' )

    // clones the layer form generated by rails and removes the h2 element since a new one with a corresponding number was created
    //var inputAndLabelFields = $('#base-form div div').first().clone()

    if(target.text === 'Muu') {
        var nameLabel = $('<label for="layer_name">Kerroksen nimi *</label>')
        var nameInput = $('<input class="span4" id="layer_name" name="layer[name]" required="required" size="30" type="text">')
        layerFormElement.append(nameLabel)
        layerFormElement.append(nameInput)
    } else {
        var name= $('<h4>' + target.text + '</h4>')
        var nameInput = $('<input class="span4" id="layer_name" name="layer[name]" size="30" type="hidden" value="'+ target.text +'">')
        layerFormElement.append(name)
        layerFormElement.append(nameInput)

    }
    var thicknessLabel = $('<label for="layer_thickness">Paksuus (cm) *</label>')
    var thicknessInput = $('<input class="span4" id="layer_thickness" name="layer[thickness]" required="required" size="30" type="text">')
    var weightLabel = $('<label for="layer_weight">Paino (kg/m2) *</label>')
    var weightInput = $('<input class="span4" id="layer_weight" name="layer[weight]" required="required" size="30" type="text">')

    layerFormElement.append(thicknessLabel)
    layerFormElement.append(thicknessInput)
    layerFormElement.append(weightLabel)
    layerFormElement.append(weightInput)

    // in case this is not the first layer of base a remove button is created, there will be no remove button
    // for the first layer since there has to be at least one layer per base.
    //if (layerCount > 1) {
    var removeButton = $('<br><button>Poista kerros</button>').attr('class', "btn btn-mini btn-danger remove-layer-button").click(removeParent)
    layerFormElement.append(removeButton)
    //}

    // clears the fields
    //inputAndLabelFields.children().each(function (index) {
    //    $(this).val("")
    //    layerFormElement.append($(this))
    //});

    return layerFormElement
}

var save = function (event) {
    var roof = createRoofObject()
    var environments = createEnvironmentsObject()
    var bases = createBasesArray()
    var greenroof = createGreenroofObjcet()

    var data = new Object()

    data.roof = roof
    data.environment = environments
    data.bases = bases
    if (plants.length < 1) {
        alert("Et valinnut yhtään kasvia")
    }
    data.plants = plants
    data.greenroof = greenroof

    sendData(data)
}

function createRoofObject() {

    var area = $('#roof_area').val()
    var declination = $('#roof_declination').val()
    var load_capacity = $('#roof_load_capacity').val()
    var locations = []
    var roof = new Object()
    roof.area = area
    roof.declination = declination
    roof.load_capacity = load_capacity

    //console.log(JSON.stringify(roof))
    return roof
}

function createEnvironmentsObject() {

    var environments = new Object()
    var id = []
    $('.selected').each(function (index) {
        id.push($(this).attr('rel'))
    });
    if (id.length < 1) {
        alert("Valitse sijainti")
    }
    environments.id = id

    //console.log(JSON.stringify(environments))
    return environments
}

function createBasesArray() {

    var bases = []

    $('#base-form > div').each(function (index) {

        var baseAndLayers = new Object()
        $(this).children('[name="base[absorbancy]"]')
        var absorbancy = $(this).children('[name="base[absorbancy]"]').val()
        var base = new Object()
        base.absorbancy = absorbancy
        baseAndLayers.base = base

        var layers = createLayerObjectArray($(this))
        baseAndLayers.layers = layers
        bases.push(baseAndLayers)
    });
    //console.log(JSON.stringify(bases))
    return bases
}

function createLayerObjectArray(baseElement) {

    var layerArray = []
    var layers = baseElement.children('div')
    layers.each(function (index) {
        console.log($(this).children($('h4')))
        var layer = new Object()
        var name = $(this).children('[name="layer[name]"]').val()
        layer.name = name
        var thickness = $(this).children('[name="layer[thickness]"]').val()
        layer.thickness = thickness
        var weight = $(this).children('[name="layer[weight]"]').val()
        layer.weight = weight
        layerArray.push(layer)
    });
    //console.log(JSON.stringify(layerArray))
    return layerArray
}

function createGreenroofObjcet() {

    var greenroof = new Object()
    greenroof.address = $('#address').val()
    greenroof.note = $('#note_').val()
    greenroof.purpose = 1
    return greenroof
}

function sendData(data) {

    $.ajax({
        url: '/greenroofs',
        type: 'POST',
        data: data,
        beforeSend: function (xhr) {
            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        },
        success: function (response) {
        }
    });
}

function setPlants(plantIDs) {
    plants = plantIDs
}