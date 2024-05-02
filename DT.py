import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
import joblib
from sklearn.tree import export_graphviz
import graphviz

# Load the CSV dataset
df = pd.read_csv(r'D:\projexct\flutter projects\student_pp-main\place-main\dataset\job_details.csv')

# Split courses in each cell and calculate frequency
course_freq = {}
for courses in df['required_skills']:
    individual_courses = courses.split(',')
    for course in individual_courses:
        course = course.strip()
        if course in course_freq:
            course_freq[course] += 1
        else:
            course_freq[course] = 1

# Assign scores based on frequency
def assign_score(freq):
    if freq > 1000:
        return 4
    elif 750 <= freq <= 1000:
        return 3
    elif 500 <= freq < 750:
        return 2
    else:
        return 1

# Create a DataFrame for decision tree training
course_df = pd.DataFrame({'Course': list(course_freq.keys()), 'Frequency': list(course_freq.values())})
course_df['Score'] = course_df['Frequency'].apply(assign_score)

# Encode course names
encoder = OneHotEncoder()
X_encoded = encoder.fit_transform(course_df[['Course']])

# Train Decision Tree Classifier
X_train, X_test, y_train, y_test = train_test_split(X_encoded, course_df['Score'], test_size=0.2, random_state=42)
clf = DecisionTreeClassifier()
clf.fit(X_train, y_train)

# Predict score for a given course
def predict_score(course):
    course_encoded = encoder.transform([[course]])
    score = clf.predict(course_encoded)
    return score[0]

# Test
test_course = input("Enter a course: ").strip()
predicted_score = predict_score(test_course)
print("Predicted score for '{}' is: {}".format(test_course, predicted_score))

# Save the decision tree model
#joblib.dump(clf, 'decision_tree_model.pkl')

# Visualize the decision tree
dot_data = export_graphviz(clf, out_file=None, feature_names=encoder.get_feature_names_out(['Course']), class_names=['1', '2', '3', '4'], filled=True, rounded=True, special_characters=True)
graph = graphviz.Source(dot_data)
graph.render('decision_tree_visualization', format='png', cleanup=True)

# Save the individual course and frequency as a CSV file to a different location
try:
    course_df.to_csv(r'D:\projexct\flutter projects\student_pp-main\datasetindividual_course_frequency.csv', index=False)
    print("Individual course and frequency data saved as 'individual_course_frequency.csv'")
except Exception as e:
    print("An error occurred while saving the CSV file:", e)

print("Decision tree model saved as 'decision_tree_model.pkl'")
print("Decision tree visualization saved as 'decision_tree_visualization.png'")
