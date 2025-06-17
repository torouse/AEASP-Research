def get_crime_schema():
    """
    Defines the expected column names for violent crime and its components for each year.
    The schema allows for flexibility if column names change over time.
    
    Returns:
        dict: A dictionary where each key is a year and the value is another dictionary
              containing the names for 'Violent Crime' and its 'Components'.
    """
    schema = {
        2012: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Forcible rape",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2013: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape (revised definition) 1"
                "Rape (legacy definition) 2",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2014: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape (revised definition) 1",
                "Rape (legacy definition) 2",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2015: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape (revised definition) 1",
                "Rape (legacy definition) 2",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2016: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape (revised definition) 1",
                "Rape (legacy definition) 2",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2017: {
            "Violent Crime": "Violent Crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape1",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2018: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape1",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2019: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape1",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2020: {
            "Violent Crime": "Violent Crime Total",
            "Components": [
                "Murder and nonnegligent manslaughter",
                "Rape 1",
                "Robbery",
                "Aggravated assault"
            ]
        },
        2021: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder",
                "Rape",
                "Robbery",
                "Aggravated Assault"
            ]
        },
        2022: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder",
                "Rape",
                "Robbery",
                "Aggravated Assault"
            ]
        },
        2023: {
            "Violent Crime": "Violent crime",
            "Components": [
                "Murder",
                "Rape",
                "Robbery",
                "Aggravated Assault"
            ]
        }
        # Add schemas for other years as needed
    }
    return schema
